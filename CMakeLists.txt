cmake_minimum_required(VERSION 3.16)

project(homestead VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(LibIcal REQUIRED)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(apphomestead
    main.cpp
)

qt_add_qml_module(apphomestead
    URI homestead
    VERSION 1.0
    SOURCES
    QML_FILES Main.qml
    QML_FILES screens/Calendar.qml
    QML_FILES components/NameTag.qml
    QML_FILES components/ChoreCard.qml
    QML_FILES components/StatsPopup.qml
    QML_FILES components/ChoreBoard.qml
    QML_FILES
    QML_FILES components/NavButton.qml
    QML_FILES components/Spacer.qml
    QML_FILES components/CalendarSchedule.qml
    #QML_FILES components/CalendarSidebar.qml
    QML_FILES components/EventDetailPopup.qml
    QML_FILES components/AddEventPopup.qml
    SOURCES sseclient.h
    SOURCES
    SOURCES
    SOURCES sseclient.cpp
    QML_FILES components/Toast.qml
    QML_FILES components/DatePicker.qml
    QML_FILES components/TimePickerPopup.qml
)

qt_add_resources(apphomestead "font_resources"
    PREFIX "/"
    FILES
    ##"fonts/Urbanist-Regular.ttf"
    #"fonts/Urbanist-Medium.ttf"
    #"fonts/Urbanist-Bold.ttf"
    #"fonts/Urbanist-SemiBold.ttf"
    "fonts/Urbanist-VariableFont_wght.ttf"
)

qt_add_resources(apphomestead "icon_resources"
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
set_target_properties(apphomestead PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.apphomestead
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(apphomestead
    PRIVATE Qt6::Quick
    ${LibIcal_LIBRARIES}
)

include(GNUInstallDirs)
install(TARGETS apphomestead
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
