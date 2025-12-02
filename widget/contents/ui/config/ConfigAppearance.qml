import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.iconthemes as KIconThemes

KCM.SimpleKCM {
    id: configPage
    
    // Icone
    property alias cfg_customIcon: iconButton.iconName
    property alias cfg_iconNormal: iconNormalButton.iconName
    property alias cfg_iconTransparency: iconTransparencyButton.iconName
    property alias cfg_iconNoiseCanceling: iconNoiseCancelingButton.iconName
    
    // Colori batteria - alias to TextField for KCM persistence
    property alias cfg_batteryColorLow: colorLowField.text
    property alias cfg_batteryColorMedium: colorMediumField.text
    property alias cfg_batteryColorHigh: colorHighField.text
    
    // Font
    property alias cfg_useSystemFont: useSystemFontCheckBox.checked
    property alias cfg_customFontFamily: fontFamilyField.text
    property alias cfg_fontSize: fontSizeSpinBox.value
    property alias cfg_titleFontSize: titleFontSizeSpinBox.value
    
    // Layout
    property alias cfg_popupWidth: popupWidthSpinBox.value
    property alias cfg_compactBadgeSize: badgeSizeSpinBox.value
    
    // Tema - alias to TextField for KCM persistence
    property alias cfg_accentColor: accentColorField.text
    property alias cfg_useCustomAccent: useCustomAccentCheckBox.checked
    
    Kirigami.FormLayout {
        anchors.fill: parent
        
        // === ICONS ===
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Icons")
        }
        
        QQC.Button {
            id: iconButton
            property string iconName: "audio-headset"
            Kirigami.FormData.label: i18n("Main icon:")
            icon.name: iconName
            text: iconName
            onClicked: iconDialog.open()
            
            KIconThemes.IconDialog {
                id: iconDialog
                onIconNameChanged: iconButton.iconName = iconName
            }
        }
        
        QQC.Button {
            id: iconNormalButton
            property string iconName: "audio-headset"
            Kirigami.FormData.label: i18n("Normal mode:")
            icon.name: iconName
            text: iconName
            onClicked: iconNormalDialog.open()
            
            KIconThemes.IconDialog {
                id: iconNormalDialog
                onIconNameChanged: iconNormalButton.iconName = iconName
            }
        }
        
        QQC.Button {
            id: iconTransparencyButton
            property string iconName: "audio-input-microphone"
            Kirigami.FormData.label: i18n("Transparency mode:")
            icon.name: iconName
            text: iconName
            onClicked: iconTransparencyDialog.open()
            
            KIconThemes.IconDialog {
                id: iconTransparencyDialog
                onIconNameChanged: iconTransparencyButton.iconName = iconName
            }
        }
        
        QQC.Button {
            id: iconNoiseCancelingButton
            property string iconName: "audio-volume-muted"
            Kirigami.FormData.label: i18n("ANC mode:")
            icon.name: iconName
            text: iconName
            onClicked: iconNoiseCancelingDialog.open()
            
            KIconThemes.IconDialog {
                id: iconNoiseCancelingDialog
                onIconNameChanged: iconNoiseCancelingButton.iconName = iconName
            }
        }
        
        // === BATTERY COLORS ===
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Battery Colors")
        }
        
        RowLayout {
            Kirigami.FormData.label: i18n("Low battery (<20%):")
            spacing: Kirigami.Units.smallSpacing
            
            Rectangle {
                width: Kirigami.Units.gridUnit * 2
                height: Kirigami.Units.gridUnit * 1.5
                color: cfg_batteryColorLow
                radius: 4
                border.color: Kirigami.Theme.textColor
                border.width: 1
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: colorDialogLow.open()
                }
            }
            
            QQC.TextField {
                id: colorLowField
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                validator: RegularExpressionValidator { regularExpression: /^#[0-9A-Fa-f]{6}$/ }
            }
        }
        
        RowLayout {
            Kirigami.FormData.label: i18n("Medium battery (20-50%):")
            spacing: Kirigami.Units.smallSpacing
            
            Rectangle {
                width: Kirigami.Units.gridUnit * 2
                height: Kirigami.Units.gridUnit * 1.5
                color: cfg_batteryColorMedium
                radius: 4
                border.color: Kirigami.Theme.textColor
                border.width: 1
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: colorDialogMedium.open()
                }
            }
            
            QQC.TextField {
                id: colorMediumField
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                validator: RegularExpressionValidator { regularExpression: /^#[0-9A-Fa-f]{6}$/ }
            }
        }
        
        RowLayout {
            Kirigami.FormData.label: i18n("High battery (>50%):")
            spacing: Kirigami.Units.smallSpacing
            
            Rectangle {
                width: Kirigami.Units.gridUnit * 2
                height: Kirigami.Units.gridUnit * 1.5
                color: cfg_batteryColorHigh
                radius: 4
                border.color: Kirigami.Theme.textColor
                border.width: 1
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: colorDialogHigh.open()
                }
            }
            
            QQC.TextField {
                id: colorHighField
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                validator: RegularExpressionValidator { regularExpression: /^#[0-9A-Fa-f]{6}$/ }
            }
        }
        
        // Color Dialogs
        ColorDialog {
            id: colorDialogLow
            title: i18n("Select low battery color")
            selectedColor: colorLowField.text || "#e74c3c"
            onAccepted: colorLowField.text = selectedColor
        }
        
        ColorDialog {
            id: colorDialogMedium
            title: i18n("Select medium battery color")
            selectedColor: colorMediumField.text || "#f39c12"
            onAccepted: colorMediumField.text = selectedColor
        }
        
        ColorDialog {
            id: colorDialogHigh
            title: i18n("Select high battery color")
            selectedColor: colorHighField.text || "#27ae60"
            onAccepted: colorHighField.text = selectedColor
        }
        
        // === FONT ===
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Font")
        }
        
        QQC.CheckBox {
            id: useSystemFontCheckBox
            Kirigami.FormData.label: i18n("System font:")
            text: i18n("Use Plasma default font")
            checked: true
        }
        
        QQC.TextField {
            id: fontFamilyField
            Kirigami.FormData.label: i18n("Custom font:")
            text: "Noto Sans"
            enabled: !useSystemFontCheckBox.checked
            Layout.preferredWidth: Kirigami.Units.gridUnit * 12
        }
        
        QQC.Label {
            text: i18n("Examples: Noto Sans, Fira Sans, Inter, JetBrains Mono")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.7
            visible: !useSystemFontCheckBox.checked
        }
        
        QQC.SpinBox {
            id: fontSizeSpinBox
            Kirigami.FormData.label: i18n("Text size:")
            from: 8
            to: 18
            value: 10
            
            textFromValue: function(value) {
                return value + " pt"
            }
        }
        
        QQC.SpinBox {
            id: titleFontSizeSpinBox
            Kirigami.FormData.label: i18n("Title size:")
            from: 10
            to: 24
            value: 14
            
            textFromValue: function(value) {
                return value + " pt"
            }
        }
        
        // === LAYOUT ===
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Layout")
        }
        
        QQC.SpinBox {
            id: popupWidthSpinBox
            Kirigami.FormData.label: i18n("Popup width:")
            from: 16
            to: 40
            value: 22
            stepSize: 2
            
            textFromValue: function(value) {
                return value + " grid units"
            }
        }
        
        QQC.SpinBox {
            id: badgeSizeSpinBox
            Kirigami.FormData.label: i18n("Badge size:")
            from: 6
            to: 14
            value: 8
            
            textFromValue: function(value) {
                return value + " px"
            }
        }
        
        // === THEME ===
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Theme")
        }
        
        QQC.CheckBox {
            id: useCustomAccentCheckBox
            Kirigami.FormData.label: i18n("Accent color:")
            text: i18n("Use custom accent color")
        }
        
        RowLayout {
            Kirigami.FormData.label: i18n("Accent color:")
            spacing: Kirigami.Units.smallSpacing
            visible: useCustomAccentCheckBox.checked
            
            Rectangle {
                width: Kirigami.Units.gridUnit * 2
                height: Kirigami.Units.gridUnit * 1.5
                color: cfg_accentColor || Kirigami.Theme.highlightColor
                radius: 4
                border.color: Kirigami.Theme.textColor
                border.width: 1
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: accentColorDialog.open()
                }
            }
            
            QQC.TextField {
                id: accentColorField
                placeholderText: "#3daee9"
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                validator: RegularExpressionValidator { regularExpression: /^#[0-9A-Fa-f]{6}$|^$/ }
            }
        }
        
        ColorDialog {
            id: accentColorDialog
            title: i18n("Select accent color")
            selectedColor: accentColorField.text || Kirigami.Theme.highlightColor
            onAccepted: accentColorField.text = selectedColor
        }
        
        // === PREVIEW ===
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Preview")
        }
        
        Rectangle {
            Kirigami.FormData.label: i18n("Battery badge:")
            width: Kirigami.Units.gridUnit * 8
            height: Kirigami.Units.gridUnit * 2
            color: "transparent"
            
            RowLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing
                
                Rectangle {
                    width: 30
                    height: 16
                    radius: 3
                    color: cfg_batteryColorLow
                    
                    QQC.Label {
                        anchors.centerIn: parent
                        text: "15%"
                        font.pixelSize: badgeSizeSpinBox.value
                        font.bold: true
                        color: "white"
                    }
                }
                
                Rectangle {
                    width: 30
                    height: 16
                    radius: 3
                    color: cfg_batteryColorMedium
                    
                    QQC.Label {
                        anchors.centerIn: parent
                        text: "40%"
                        font.pixelSize: badgeSizeSpinBox.value
                        font.bold: true
                        color: "white"
                    }
                }
                
                Rectangle {
                    width: 30
                    height: 16
                    radius: 3
                    color: cfg_batteryColorHigh
                    
                    QQC.Label {
                        anchors.centerIn: parent
                        text: "80%"
                        font.pixelSize: badgeSizeSpinBox.value
                        font.bold: true
                        color: "white"
                    }
                }
            }
        }
    }
}
