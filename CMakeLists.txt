cmake_minimum_required(VERSION 3.16)

project(focalis_ui VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTORCC ON)

set(QT_NO_ASSET_FORWARDING TRUE)
set(QT_NO_IMPORT_QML_PLUGINS TRUE)


find_package(Qt6 6.8.1 REQUIRED COMPONENTS Core DBus Quick Qml)

#find_package(Qt6 COMPONENTS  REQUIRED)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(focalis
    main.cpp
)


#qt_add_qml_module(focalis
#    URI focalis_ui
#    VERSION 1.0
#    SOURCES
#    QML_FILES Main.qml
#    QML_FILES components/NameTag.qml
#    QML_FILES components/ChoreCard.qml
#    QML_FILES components/StatsPopup.qml
#    QML_FILES components/ChoreBoard.qml
#    QML_FILES
#    QML_FILES components/NavButton.qml
#    QML_FILES components/Spacer.qml
#    QML_FILES components/CalendarSchedule.qml
#    QML_FILES components/EventDetailPopup.qml
#    QML_FILES components/AddEventPopup.qml
#    SOURCES sseclient.h
#    SOURCES
#    SOURCES
#    SOURCES sseclient.cpp
#    QML_FILES components/Toast.qml
#    QML_FILES components/DatePicker.qml
#    QML_FILES components/TimePickerPopup.qml
#    DEPENDENCIES
#            QtQuick
#            QtQml
#            QML_FILES api.js
#            QML_FILES components/Daydream.qml
#            SOURCES InputFilter.h
#)
qt_add_qml_module(focalis
    URI focalis_ui
    VERSION 1.0
    SOURCES
        main.cpp          # Make sure your main.cpp is listed!
        sseclient.h
        sseclient.cpp
        InputFilter.h
    QML_FILES
        Main.qml
        api.js
        components/NameTag.qml
        components/ChoreCard.qml
        components/StatsPopup.qml
        components/ChoreBoard.qml
        components/NavButton.qml
        components/Spacer.qml
        components/CalendarSchedule.qml
        components/EventDetailPopup.qml
        components/AddEventPopup.qml
        components/Toast.qml
        components/DatePicker.qml
        components/TimePickerPopup.qml
        components/Daydream.qml
    DEPENDENCIES
        QtQuick
        QtQml
)

qt_add_resources(focalis "font_resources"
    PREFIX "/"
    FILES
    "fonts/Urbanist-VariableFont_wght.ttf"
)

qt_add_resources(focalis "icon_resources"
    PREFIX "/"
    FILES
    "images/icons/calendar.svg"
    "images/icons/chores.svg"
    "images/icons/prizes.svg"
    "images/icons/brushing.svg"
    "images/icons/settings.svg"
)


# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(focalis PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.focalis
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

#target_link_libraries(focalis
#    PRIVATE Qt6::Quick
#)

target_link_libraries(focalis PRIVATE
    Qt6::Core
#    Qt6::DBus
    Qt6::Core
    Qt6::Qml
    Qt6::Quick
)

include(GNUInstallDirs)
install(TARGETS focalis
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

qt_finalize_target(focalis)
