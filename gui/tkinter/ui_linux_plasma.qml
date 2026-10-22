import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
	id: root
	title: qsTr("Hello world")
	minimumWidth:  Kirigami.Units.gridUnit * 20
	minimumHeight: Kirigami.Units.gridUnit * 20
	width:  minimumWidth
	height: minimumHeight
	pageStack.initialPage: initPage
	Component {
		id: initPage
		Kirigami.Page {
			title: qsTr("Lol")
			ColumnLayout {
				anchors {
					top: parent.top
					left: parent.left
					right: parent.right
				}
				Controls.TextArea {
					id: sourceArea
					placeholderText: qsTr("smdf")
					wrapMode: Text.WrapAnywhere
					Layout.fillWidth: true
					Layout.minimumHeight: Kirigami.Units.gridUnit * 5
				}
				RowLayout {
					Layout.fillWidth: true
					Controls.Button {
						text: qsTr("Set")
						onClicked: formattedText.text = sourceArea.text
					}
					Controls.Button {
						text: qsTr("Reset")
						onClicked: {
							sourceArea.text = ""
							formattedText.text = ""
						}
					}
				}
				Text {
					id: formattedText
					textFormat: Text.RichText
					wrapMode: Text.WordWrap
					text: sourceArea.text
					Layout.fillWidth: true
					Layout.minimumHeight: Kirigami.Units.gridUnit * 5
				}
			}
		}
	}
}
