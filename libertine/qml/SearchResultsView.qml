/**
 * @file SearchResultsView.qml
 * @brief Libertine search packages results view
 */
/*
 * Copyright 2016 Canonical Ltd
 *
 * Libertine is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3, as published by the
 * Free Software Foundation.
 *
 * Libertine is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import Libertine 1.0
import QtQuick 2.4
import QtQuick.Layouts 1.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3


Page {
    id: searchResultsView
    header: PageHeader {
        id: pageHeader
        z: 1000
        title: i18n.tr("Package Search Results")
        trailingActionBar.actions: [
            Action {
                iconName: "search"
                text: i18n.tr("Search")
                description: i18n.tr("Search for packages")

                onTriggered: doSearch()
            }
        ]
    }
    objectName: "searchResultsView"
    property var search_string: null
    property var search_comp: null
    property var search_obj: null
    signal doSearch

    Component {
        id: noResultsPopup
        Dialog {
            id: noResultsDialog
            title: i18n.tr("No Search Results Found")
            property var returnHome: false

            Button {
                id: searchAgain
                text: i18n.tr("Search Again")
                color: UbuntuColors.green
                onClicked: {
                    PopupUtils.close(noResultsDialog)
                    PopupUtils.open(Qt.resolvedUrl("SearchPackagesDialog.qml"))
                }
            }

            Button {
                id: returnToHomeView
                text: i18n.tr("Return to Apps Page")
                onClicked: {
                    noResultsDialog.returnHome = true
                    PopupUtils.close(noResultsDialog)
                }
            }

            Component.onDestruction: {
                if (returnHome) {
                    pageStack.pop()
                }
            }
        }
    }

    ActivityIndicator {
        id: searchActivity
        visible: false
        running: searchActivity.visible
        anchors {
            top: parent.top
            topMargin: units.gu(2) + pageHeader.height
            left: parent.left
            leftMargin: units.gu(2)
        }
    }
    Label {
        id: searchLabel
        text: i18n.tr("Searching for packages…")
        visible: searchActivity.running
        anchors {
            left: searchActivity.right
            top: parent.top
            leftMargin: units.gu(2)
            topMargin: units.gu(2) + pageHeader.height
        }
    }

    ListModel {
        id: packageListModel
    }

    Component.onCompleted: {
        searchForPackages(search_string)
    }

    function searchForPackages(search_string) {
        searchActivity.visible = true

        if (search_obj) {
            search_obj.destroy()
        }
        packageListModel.clear()

        var comp = Qt.createComponent("ContainerManager.qml")
        var worker = comp.createObject()
        worker.containerAction = ContainerManagerWorker.Search
        worker.containerId = mainView.currentContainer
        worker.data = search_string
        worker.finishedSearch.connect(finishedSearch)
        worker.start()
    }     

    function finishedSearch(result, packageList) {
        searchActivity.visible = false
        if (result) {
            for (var i = 0; i < packageList.length; ++i)
            {
                packageListModel.append({"package_desc": packageList[i], "package_name": packageList[i].split(' ')[0]})
            }
            if (!search_comp) {
                search_comp = Qt.createComponent("SearchResults.qml")
            }
            search_obj = search_comp.createObject(searchResultsView, {"model": packageListModel})
        }
        else {
            PopupUtils.open(noResultsPopup)
        }
    }

    onDoSearch: PopupUtils.open(Qt.resolvedUrl("SearchPackagesDialog.qml"))
}
