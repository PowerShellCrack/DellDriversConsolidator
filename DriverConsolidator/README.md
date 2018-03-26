     
       Title: Dell Driver Consolidator
       Created: 2018-03-22
       Author: Richard tracy

## GOALS: ##
   Inventory all extracted Dell Driver CABs in folder. Compare them, copying only unique folders to AIO folder.
   Then parse all driver inf and consolidate the unique ones. 

Name convention must be
 
    [model]-[OS]-[ver]-[build]\[model]\[OS]\[arch]\[drivertype]
 
 e.g.
           
    E6530-win10-A01-PXT6R\E6530\win10\x64
    E6540-win10-A03-FHWDF\E6540\win10\x86


Source: http://www.powershellcrack.com/2018/03/consolidate-dell-drivers-part-1.html
