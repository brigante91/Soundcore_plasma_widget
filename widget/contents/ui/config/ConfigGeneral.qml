import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as P5Support

KCM.SimpleKCM {
    id: configPage
    
    property alias cfg_macAddress: macAddressField.text
    property alias cfg_refreshInterval: refreshIntervalSpinBox.value
    property alias cfg_showBatteryBadge: showBatteryBadgeCheckBox.checked
    property alias cfg_autoConnect: autoConnectCheckBox.checked
    
    // Lista dispositivi Bluetooth
    property var bluetoothDevices: []
    property bool isScanning: false
    
    // DataSource per eseguire comandi
    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        
        onNewData: function(sourceName, data) {
            var stdout = data["stdout"] || "";
            var exitCode = data["exit code"] || 0;
            
            if (sourceName.indexOf("bluetoothctl devices") !== -1) {
                parseBluetoothDevices(stdout);
            }
            
            configPage.isScanning = false;
            disconnectSource(sourceName);
        }
    }
    
    // Funzione per parsare i dispositivi Bluetooth
    function parseBluetoothDevices(output) {
        var lines = output.trim().split("\n");
        var devices = [];
        
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            // Formato: "Device XX:XX:XX:XX:XX:XX Nome Dispositivo"
            var match = line.match(/^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/);
            if (match) {
                devices.push({
                    mac: match[1].toUpperCase(),
                    name: match[2]
                });
            }
        }
        
        bluetoothDevices = devices;
        
        // Aggiorna il model del ComboBox
        var model = [i18n("-- Select device --")];
        for (var j = 0; j < devices.length; j++) {
            model.push(devices[j].name + " (" + devices[j].mac + ")");
        }
        deviceComboBox.model = model;
        
        // Se c'è già un MAC configurato, selezionalo
        if (cfg_macAddress) {
            for (var k = 0; k < devices.length; k++) {
                if (devices[k].mac === cfg_macAddress.toUpperCase()) {
                    deviceComboBox.currentIndex = k + 1;
                    break;
                }
            }
        }
    }
    
    // Scansiona dispositivi Bluetooth paired
    function scanDevices() {
        isScanning = true;
        executable.connectSource("bluetoothctl devices");
    }
    
    // Carica dispositivi all'avvio
    Component.onCompleted: {
        scanDevices();
    }
    
    Kirigami.FormLayout {
        anchors.fill: parent
        
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Device")
        }
        
        RowLayout {
            Kirigami.FormData.label: i18n("Bluetooth device:")
            spacing: Kirigami.Units.smallSpacing
            
            QQC.ComboBox {
                id: deviceComboBox
                Layout.fillWidth: true
                model: [i18n("-- Select device --")]
                
                onActivated: function(index) {
                    if (index > 0 && index <= bluetoothDevices.length) {
                        var device = bluetoothDevices[index - 1];
                        macAddressField.text = device.mac;
                    }
                }
            }
            
            QQC.Button {
                icon.name: "view-refresh"
                enabled: !isScanning
                onClicked: scanDevices()
                
                QQC.ToolTip.text: i18n("Refresh device list")
                QQC.ToolTip.visible: hovered
                
                QQC.BusyIndicator {
                    anchors.centerIn: parent
                    running: isScanning
                    visible: isScanning
                    width: parent.width * 0.6
                    height: parent.height * 0.6
                }
            }
        }
        
        QQC.Label {
            text: i18n("Select your Soundcore headphones from paired Bluetooth devices")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.7
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        
        QQC.TextField {
            id: macAddressField
            Kirigami.FormData.label: i18n("MAC Address:")
            placeholderText: "XX:XX:XX:XX:XX:XX"
            inputMask: "HH:HH:HH:HH:HH:HH;_"
            font.family: "monospace"
            Layout.preferredWidth: Kirigami.Units.gridUnit * 12
        }
        
        QQC.Label {
            text: i18n("Or enter manually if device not listed above")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.7
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Refresh")
        }
        
        QQC.SpinBox {
            id: refreshIntervalSpinBox
            Kirigami.FormData.label: i18n("Interval (seconds):")
            from: 5
            to: 300
            stepSize: 5
            
            textFromValue: function(value) {
                return value + " sec"
            }
            
            valueFromText: function(text) {
                return parseInt(text) || 30
            }
        }
        
        QQC.Label {
            text: i18n("How often to update headphone status (battery, mode, etc.)")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.7
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Display")
        }
        
        QQC.CheckBox {
            id: showBatteryBadgeCheckBox
            Kirigami.FormData.label: i18n("Battery badge:")
            text: i18n("Show battery indicator on icon")
        }
        
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Behavior")
        }
        
        QQC.CheckBox {
            id: autoConnectCheckBox
            Kirigami.FormData.label: i18n("Auto-connect:")
            text: i18n("Automatically refresh on startup")
        }
    }
}
