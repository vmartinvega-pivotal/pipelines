testrunner.sh -s "ID_20_Consistenze" -c "SB API - Post semplice" -G Ambiente=COLLEVO -f ./ID_20_Consistenze/Reports/ -r -j -J -A ./ID_20_Consistenze/ID_20_Consistenze-soapui-project.xml
testrunner.sh -s "ID_20_Consistenze" -c "NB API - rifCliente - Validazione vs JsonSchema" -G Ambiente=COLLEVO -f ./ID_20_Consistenze/Reports/ -r -j -J -A ./ID_20_Consistenze/ID_20_Consistenze-soapui-project.xml
testrunner.sh -s "ID_20_Consistenze" -c "NB API - rifCliente-numLinea - Validazione vs JsonSchema" -G Ambiente=COLLEVO -f ./ID_20_Consistenze/Reports/ -r -j -J -A ./ID_20_Consistenze/ID_20_Consistenze-soapui-project.xml

