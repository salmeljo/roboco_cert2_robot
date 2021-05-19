*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.HTTP
Library    Browser
Library    RPA.Browser
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Dialogs
Library    RPA.Robocloud.Secrets
#Library    variables/variables.py

*** Variables ***
#${ORDER_CSV_URL}    https://robotsparebinindustries.com/orders.csv
#${ORDER_PAGE}       https://robotsparebinindustries.com/#/robot-order
${ORDER_FILE}       orders.csv
&{RADIO_BODY}    1=Roll-a-thor body    2=Peanut crusher body   3=D.A.V.E body    4=Andy Roid body    5=Spanner mate body    6=Drillbit 2000 body     

*** Keywords ***
Get robot order secret website
    ${secret}=    Get Secret    robotorderpage
    [Return]    ${secret}

*** Keywords ***
Ask order CSV url from user
    Create Form    Order CSV url form
    Add Text Input    Order CSV url    url
    &{response}=    Request Response
    [Return]    ${response["url"]}

*** Keywords ***
Close modal
    Click    button.btn.btn-dark

*** Keywords ***
Get orders
    [Arguments]    ${order_csv_url}
    RPA.HTTP.Download    ${order_csv_url}    target_file=orders.csv    overwrite=True
    ${table}=    Read Table From Csv    ${ORDER_FILE}
    Log    Found columns: ${table.columns} 
    [Return]    ${table}

*** Keywords ***
Open the robot order website
    [Arguments]    ${url}
    Browser.Open Browser
    New Page    ${url}

*** Keywords ***
Preview robot
    Click    text=Preview

*** Keywords ***
Submit order
    [Arguments]    ${order_number}
    Click    button#order
    Log To Console    Processing order ${order_number}
    Wait For Elements State    text=Receipt

*** Keywords ***
Order another
    Click    button#order-another
    
*** Keywords ***
Store the receipt as a PDF file
    ${receipt}=    Get Property    css=#receipt    outerHTML
    #Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}receipts${/}robot_order_receipt_id${order_number}.pdf
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}temp_robot_order_receipt.pdf

Take robot screenshot
    Wait For Elements State    id=robot-preview-image    timeout=4
    Sleep    1.5s
    #Take Screenshot    ${OUTPUT_DIR}${/}receipts${/}robot_figure_id${order_number}    id=robot-preview
    Take Screenshot    ${OUTPUT_DIR}${/}temp_robot_order_figure    id=robot-preview

Embed screenshot to PDF receipt
    [Arguments]    ${order_number}
    ${current_robot_files}=    Create List
    ...    ${OUTPUT_DIR}${/}temp_robot_order_receipt.pdf    
    ...    ${OUTPUT_DIR}${/}temp_robot_order_figure.png
    Add Files To Pdf    ${current_robot_files}    ${OUTPUT_DIR}${/}receipts${/}robot_order_receipt_id${order_number}.pdf

*** Keywords ***
Fill form
    [Arguments]    ${row}
    Browser.Select Options By    select#head    value    ${row}[Head]
    #Log To Console    ${RADIO_BODY}[${row}[Body]]    
    ${click_this}=    Convert To String    ${RADIO_BODY}[${row}[Body]]
    Click    text=${click_this}
    Fill Text    css=div.form-group > input[type="number"]    ${row}[Legs]
    Fill Text    input#address    ${row}[Address]
    Click    text=Preview
 
*** Keywords ***
Order robots
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Close modal
        Fill form    ${order}
        Preview robot
        #Log To Console    hurry!
        Wait Until Keyword Succeeds    5x    1 sec    Submit order    ${order}[Order number]
        Store the receipt as a PDF file
        Take robot screenshot
        Embed screenshot to PDF receipt    ${order}[Order number]    
        Click    button#order-another
        #Log To Console    UP!
    END

*** Keywords ***
Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/robot_receipt_PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}receipts
    ...    ${zip_file_name}    

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${order_csv_url}=    Ask order CSV url from user
    ${order_website}=    Get robot order secret website
    Open the robot order website    ${order_website}
    #Get orders
    #Order robots
    #Create ZIP package from PDF files