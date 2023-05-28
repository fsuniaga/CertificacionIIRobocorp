*** Settings ***
Documentation       Template robot main suite.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.RobotLogListener


*** Variables ***
${LinkArchivo}=             https://robotsparebinindustries.com/orders.csv
${ArchivosTemporales}=      ${OUTPUT_DIR}${/}ArchivosTemporales
${PathOrdenesPDF}=          ${OUTPUT_DIR}${/}OrdenesPDF


*** Tasks ***
Template robot main suite
    Abrir sitio web
    Leer archivo
    Crear archivo comprimido
    Eliminar carpeta archivos temporales
    [Teardown]    Cerrar Navegador


*** Keywords ***
Abrir sitio web
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Cerrar modal
    Wait Until Element Is Enabled    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Click Button    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Leer archivo
    Download    ${LinkArchivo}    target_file=${OUTPUT_DIR}${/}ordenes.csv    overwrite=${False}
    ${ordenes}=    Read table from CSV    ${OUTPUT_DIR}${/}ordenes.csv
    FOR    ${orden}    IN    @{ordenes}
        Cerrar modal
        Ingresar orden    ${orden}
        Wait Until Element Is Enabled    order-another
        Generar otra orden
    END

Ingresar orden
    [Arguments]    ${orden}
    Mute Run On Failure    Run Keyword
    Select From List By Value    head    ${orden}[Head]
    Click Element    //label[./input[@value=${orden}[Body]]]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${orden}[Legs]
    Input Text    address    ${orden}[Address]
    Wait Until Keyword Succeeds    3x    0.5 sec    Previsualizar robot
    Wait Until Keyword Succeeds    5x    0.5 sec    Ordenar robot
    Obtener numero orden
    ${nroOrden}=    Get Text    //*[@id="receipt"]/p[1]
    IF    '${nroOrden}' == 'None'    Input Text    12345    123
    Generar PDF    ${nroOrden}

Previsualizar robot
    Click Button    preview

Ordenar robot
    Click Button    order

Obtener numero orden
    TRY
        Wait Until Element Is Visible    //*[@id="receipt"]/p[1]
        RETURN
    EXCEPT
        Click Button    order
        Obtener numero orden
    END

Generar otra orden
    Click Button    order-another

Generar PDF
    [Arguments]    ${nroOrden}
    ${orden_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${orden_html}    ${ArchivosTemporales}${/}Orden_${nroOrden}.pdf
    Screenshot    id:robot-preview-image    ${ArchivosTemporales}${/}Orden_${nroOrden}.png
    Add Watermark Image To PDF
    ...    image_path=${ArchivosTemporales}${/}Orden_${nroOrden}.png
    ...    source_path=${ArchivosTemporales}${/}Orden_${nroOrden}.pdf
    ...    output_path=${PathOrdenesPDF}${/}Orden_${nroOrden}.pdf

Crear archivo comprimido
    ${nombreZip}=    Set Variable    ${OUTPUT_DIR}/Ordenes.zip
    Archive Folder With Zip
    ...    ${PathOrdenesPDF}
    ...    ${nombreZip}

Eliminar carpeta archivos temporales
    Remove Directory    ${ArchivosTemporales}    True

Cerrar Navegador
    Close Browser
