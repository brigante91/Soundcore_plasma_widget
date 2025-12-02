import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    
    // Configurazioni dal pannello impostazioni - Generale
    readonly property string macAddress: Plasmoid.configuration.macAddress
    readonly property int refreshInterval: Plasmoid.configuration.refreshInterval
    readonly property bool showBatteryBadge: Plasmoid.configuration.showBatteryBadge
    readonly property bool autoConnect: Plasmoid.configuration.autoConnect
    
    // Configurazioni - Aspetto: Icone
    readonly property string customIcon: Plasmoid.configuration.customIcon || "audio-headset"
    readonly property string iconNormal: Plasmoid.configuration.iconNormal || "audio-headset"
    readonly property string iconTransparency: Plasmoid.configuration.iconTransparency || "audio-input-microphone"
    readonly property string iconNoiseCanceling: Plasmoid.configuration.iconNoiseCanceling || "audio-volume-muted"
    
    // Configurazioni - Aspetto: Colori batteria
    readonly property string batteryColorLow: Plasmoid.configuration.batteryColorLow || "#e74c3c"
    readonly property string batteryColorMedium: Plasmoid.configuration.batteryColorMedium || "#f39c12"
    readonly property string batteryColorHigh: Plasmoid.configuration.batteryColorHigh || "#27ae60"
    
    // Configurazioni - Aspetto: Font
    readonly property bool useSystemFont: Plasmoid.configuration.useSystemFont
    readonly property string customFontFamily: Plasmoid.configuration.customFontFamily || "Noto Sans"
    readonly property int fontSize: Plasmoid.configuration.fontSize || 10
    readonly property int titleFontSize: Plasmoid.configuration.titleFontSize || 14
    
    // Configurazioni - Aspetto: Layout
    readonly property int popupWidth: Plasmoid.configuration.popupWidth || 22
    readonly property int compactBadgeSize: Plasmoid.configuration.compactBadgeSize || 8
    
    // Configurazioni - Aspetto: Tema
    readonly property bool useCustomAccent: Plasmoid.configuration.useCustomAccent
    readonly property string accentColor: Plasmoid.configuration.accentColor || ""
    
    // Helper per font
    readonly property string displayFont: useSystemFont ? Kirigami.Theme.defaultFont.family : customFontFamily
    
    // Proprietà stato
    property int batteryLevel: -1
    property string soundMode: "--"
    property string eqPreset: "--"
    property bool isCharging: false
    property bool connected: false
    property string firmwareVersion: "--"
    property string serialNumber: "--"
    
    // Liste preset equalizzatore
    readonly property var eqPresets: [
        "SoundcoreSignature", "Acoustic", "BassBooster", "BassReducer", 
        "Classical", "Podcast", "Dance", "Deep", "Electronic", "Flat", 
        "HipHop", "Jazz", "Latin", "Lounge", "Piano", "Pop", 
        "RnB", "Rock", "SmallSpeakers", "SpokenWord", "TrebleBooster", "TrebleReducer"
    ]
    
    // Tooltip
    Plasmoid.icon: customIcon
    toolTipMainText: "Soundcore Q20i"
    toolTipSubText: connected ? 
        "🔋 " + batteryLevel + "%" + (isCharging ? " ⚡" : "") + " | " + soundMode + " | EQ: " + eqPreset :
        i18n("Disconnected")
    
    // Contatore fallimenti consecutivi
    property int failureCount: 0
    
    // DataSource per eseguire comandi
    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        
        onNewData: function(sourceName, data) {
            var stdout = data["stdout"] || "";
            var stderr = data["stderr"] || "";
            var exitCode = data["exit code"] || 0;
            
            // Solo per comandi di lettura status
            if (sourceName.indexOf("setting -j") !== -1) {
                if (exitCode === 0 && stdout.trim().length > 10) {
                    root.failureCount = 0;
                    parseJsonStatus(stdout.trim());
                } else {
                    root.failureCount++;
                    // Dopo 3 fallimenti consecutivi, considera disconnesso
                    if (root.failureCount >= 3) {
                        root.connected = false;
                    }
                }
            }
            
            disconnectSource(sourceName);
        }
    }
    
    // Timer per aggiornamento automatico
    Timer {
        interval: root.refreshInterval * 1000  // Converti secondi in millisecondi
        running: true
        repeat: true
        onTriggered: updateStatus()
    }
    
    // Timer per ritardo dopo set command
    Timer {
        id: delayedUpdateTimer
        interval: 1500  // 1.5 secondi di attesa dopo un comando set
        running: false
        repeat: false
        onTriggered: updateStatus()
    }
    
    // Funzione per parsare lo stato JSON
    function parseJsonStatus(jsonStr) {
        // Se la stringa è vuota o non valida, non fare nulla (mantieni stato precedente)
        if (!jsonStr || jsonStr.length < 10) {
            return;
        }
        
        try {
            var data = JSON.parse(jsonStr);
            
            // Se il parsing ha successo, siamo connessi
            if (data && data.length > 0) {
                connected = true;
                
                for (var i = 0; i < data.length; i++) {
                    var item = data[i];
                    var value = item.value.value;
                    
                    switch (item.settingId) {
                        case "batteryLevel":
                            // Il CLI restituisce livelli 0-5, convertiamo in percentuale
                            var level = parseInt(value) || 0;
                            batteryLevel = level * 20; // 0=0%, 1=20%, 2=40%, 3=60%, 4=80%, 5=100%
                            break;
                        case "ambientSoundMode":
                            soundMode = value || soundMode;
                            break;
                        case "isCharging":
                            isCharging = (value === "Yes");
                            break;
                        case "firmwareVersion":
                            firmwareVersion = value || firmwareVersion;
                            break;
                        case "serialNumber":
                            serialNumber = value || serialNumber;
                            break;
                        case "presetEqualizerProfile":
                            eqPreset = value || "Custom";
                            break;
                    }
                }
            }
        } catch (e) {
            // In caso di errore di parsing, non cambiare lo stato di connessione
            // Potrebbe essere un errore temporaneo
            console.log("Soundcore: JSON parsing error - " + e.message);
        }
    }
    
    // Funzione per aggiornare lo stato
    function updateStatus() {
        var cmd = "openscq30 device --mac-address '" + macAddress + "' setting -j " +
                  "-g batteryLevel -g ambientSoundMode -g isCharging " +
                  "-g firmwareVersion -g presetEqualizerProfile 2>/dev/null";
        executable.connectSource(cmd);
    }
    
    // Funzione per impostare modalità audio
    function setSoundMode(mode) {
        var cmd = "openscq30 device --mac-address '" + macAddress + "' setting -s 'ambientSoundMode=" + mode + "' 2>/dev/null";
        executable.connectSource(cmd);
        soundMode = mode;  // Aggiorna subito localmente per feedback immediato
        delayedUpdateTimer.restart();  // Aggiorna stato dopo delay
    }
    
    // Funzione per impostare preset EQ
    function setEqPreset(preset) {
        var cmd = "openscq30 device --mac-address '" + macAddress + "' setting -s 'presetEqualizerProfile=" + preset + "' 2>/dev/null";
        executable.connectSource(cmd);
        eqPreset = preset;  // Aggiorna subito localmente per feedback immediato
        delayedUpdateTimer.restart();  // Aggiorna stato dopo delay
    }
    
    
    // Rappresentazione compatta (icona nella barra)
    compactRepresentation: MouseArea {
        id: compactRoot
        
        Layout.minimumWidth: Kirigami.Units.iconSizes.medium
        Layout.minimumHeight: Kirigami.Units.iconSizes.medium
        Layout.preferredWidth: Layout.minimumWidth
        Layout.preferredHeight: Layout.minimumHeight
        
        onClicked: root.expanded = !root.expanded
        
        Kirigami.Icon {
            anchors.fill: parent
            source: {
                if (!root.connected) return root.customIcon;
                if (root.soundMode === "NoiseCanceling") return root.iconNoiseCanceling;
                if (root.soundMode === "Transparency") return root.iconTransparency;
                return root.iconNormal;
            }
            opacity: root.connected ? 1.0 : 0.5
        }
        
        // Badge batteria
        Rectangle {
            anchors {
                bottom: parent.bottom
                right: parent.right
                margins: -2
            }
            width: batteryText.width + 4
            height: batteryText.height + 2
            radius: 2
            color: {
                if (!root.connected || root.batteryLevel < 0) return "transparent";
                if (root.batteryLevel < 20) return root.batteryColorLow;
                if (root.batteryLevel < 50) return root.batteryColorMedium;
                return root.batteryColorHigh;
            }
            visible: root.showBatteryBadge && root.connected && root.batteryLevel >= 0
            
            PlasmaComponents.Label {
                id: batteryText
                anchors.centerIn: parent
                text: root.batteryLevel + "%" + (root.isCharging ? "⚡" : "")
                font.pixelSize: root.compactBadgeSize
                font.bold: true
                color: "white"
            }
        }
    }
    
    // Rappresentazione completa (popup)
    fullRepresentation: PlasmaExtras.Representation {
        Layout.preferredWidth: Kirigami.Units.gridUnit * root.popupWidth
        Layout.preferredHeight: Kirigami.Units.gridUnit * 20
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.minimumHeight: Kirigami.Units.gridUnit * 14
        
        // Font personalizzato per tutto il popup
        font.family: root.displayFont
        font.pointSize: root.fontSize
        
        header: PlasmaExtras.PlasmoidHeading {
            RowLayout {
                anchors.fill: parent
                
                Kirigami.Icon {
                    source: root.customIcon
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                }
                
                ColumnLayout {
                    spacing: 0
                    PlasmaExtras.Heading {
                        text: "Soundcore Q20i"
                        level: 3
                        font.family: root.displayFont
                        font.pointSize: root.titleFontSize
                    }
                    PlasmaComponents.Label {
                        text: root.connected ? i18n("Connected") : i18n("Disconnected")
                        opacity: 0.7
                        font.family: root.displayFont
                        font.pointSize: root.fontSize - 2
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                PlasmaComponents.ToolButton {
                    icon.name: "view-refresh"
                    onClicked: updateStatus()
                    PlasmaComponents.ToolTip.text: i18n("Refresh")
                    PlasmaComponents.ToolTip.visible: hovered
                }
            }
        }
        
        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            
            // Stato batteria
            Kirigami.AbstractCard {
                Layout.fillWidth: true
                visible: root.connected
                
                contentItem: RowLayout {
                    spacing: Kirigami.Units.largeSpacing
                    
                    Kirigami.Icon {
                        source: root.isCharging ? "battery-charging" : 
                                (root.batteryLevel > 80 ? "battery-100" :
                                 root.batteryLevel > 60 ? "battery-080" :
                                 root.batteryLevel > 40 ? "battery-060" :
                                 root.batteryLevel > 20 ? "battery-040" : "battery-low")
                        Layout.preferredWidth: Kirigami.Units.iconSizes.large
                        Layout.preferredHeight: Kirigami.Units.iconSizes.large
                    }
                    
                    ColumnLayout {
                        spacing: 2
                        PlasmaComponents.Label {
                            text: i18n("Battery")
                            font.bold: true
                        }
                        PlasmaComponents.Label {
                            text: root.batteryLevel + "%" + (root.isCharging ? " " + i18n("(Charging)") : "")
                            opacity: 0.8
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    PlasmaComponents.ProgressBar {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                        from: 0
                        to: 100
                        value: Math.max(0, root.batteryLevel)
                    }
                }
            }
            
            // Modalità Audio
            Kirigami.AbstractCard {
                Layout.fillWidth: true
                visible: root.connected
                
                contentItem: ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing
                    
                    PlasmaComponents.Label {
                        text: i18n("Sound Mode")
                        font.bold: true
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        
                        PlasmaComponents.Button {
                            Layout.fillWidth: true
                            text: i18n("Normal")
                            icon.name: "audio-headset"
                            checked: root.soundMode === "Normal"
                            checkable: true
                            onClicked: setSoundMode("Normal")
                        }
                        
                        PlasmaComponents.Button {
                            Layout.fillWidth: true
                            text: i18n("Transparency")
                            icon.name: "audio-input-microphone"
                            checked: root.soundMode === "Transparency"
                            checkable: true
                            onClicked: setSoundMode("Transparency")
                        }
                        
                        PlasmaComponents.Button {
                            Layout.fillWidth: true
                            text: i18n("ANC")
                            icon.name: "audio-volume-muted"
                            checked: root.soundMode === "NoiseCanceling"
                            checkable: true
                            onClicked: setSoundMode("NoiseCanceling")
                        }
                    }
                }
            }
            
            // Equalizzatore
            Kirigami.AbstractCard {
                Layout.fillWidth: true
                visible: root.connected
                
                contentItem: ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing
                    
                    RowLayout {
                        PlasmaComponents.Label {
                            text: i18n("Equalizer")
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label {
                            text: root.eqPreset
                            opacity: 0.7
                        }
                    }
                    
                    PlasmaComponents.ComboBox {
                        id: eqComboBox
                        Layout.fillWidth: true
                        model: root.eqPresets
                        currentIndex: {
                            var idx = root.eqPresets.indexOf(root.eqPreset);
                            return idx >= 0 ? idx : 0;
                        }
                        onActivated: function(index) {
                            setEqPreset(root.eqPresets[index]);
                        }
                        // Update when eqPreset changes externally
                        Connections {
                            target: root
                            function onEqPresetChanged() {
                                var idx = root.eqPresets.indexOf(root.eqPreset);
                                if (idx >= 0) {
                                    eqComboBox.currentIndex = idx;
                                }
                            }
                        }
                    }
                }
            }
            
            // Info dispositivo
            Kirigami.AbstractCard {
                Layout.fillWidth: true
                visible: root.connected
                
                contentItem: ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing
                    
                    PlasmaComponents.Label {
                        text: i18n("Information")
                        font.bold: true
                    }
                    
                    GridLayout {
                        columns: 2
                        rowSpacing: 2
                        columnSpacing: Kirigami.Units.largeSpacing
                        
                        PlasmaComponents.Label { text: i18n("Firmware:"); opacity: 0.7 }
                        PlasmaComponents.Label { text: root.firmwareVersion }
                        
                        PlasmaComponents.Label { text: i18n("MAC:"); opacity: 0.7 }
                        PlasmaComponents.Label { text: root.macAddress; font.family: "monospace" }
                    }
                }
            }
            
            // Messaggio disconnesso
            Kirigami.AbstractCard {
                Layout.fillWidth: true
                visible: !root.connected
                
                contentItem: ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing
                    
                    Kirigami.Icon {
                        source: "network-bluetooth-inactive"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                        Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                        Layout.alignment: Qt.AlignHCenter
                        opacity: 0.5
                    }
                    
                    PlasmaComponents.Label {
                        text: i18n("Headphones not connected")
                        Layout.alignment: Qt.AlignHCenter
                        font.bold: true
                    }
                    
                    PlasmaComponents.Label {
                        text: i18n("Make sure headphones are powered on\nand connected via Bluetooth")
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        opacity: 0.7
                    }
                    
                    PlasmaComponents.Button {
                        text: i18n("Retry")
                        icon.name: "view-refresh"
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: updateStatus()
                    }
                }
            }
            
            Item { Layout.fillHeight: true }
        }
    }
    
    // Inizializza
    Component.onCompleted: {
        if (root.autoConnect) {
            updateStatus();
        }
    }
}
