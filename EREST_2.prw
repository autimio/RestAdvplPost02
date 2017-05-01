#Include 'protheus.ch'
#Include 'parmtype.ch'
#Include 'RestFul.ch'

/*/{Protheus.doc} EREST_02
__Dummy function
@author Victor Andrade
@since 20/04/2017
@version 1
@type function
/*/
User Function EREST_2()	
Return

/*/{Protheus.doc} CLIENTES
WebService Rest para realizar a manipula��o de clientes
@author Victor Andrade
@since 20/04/2017
@type class
/*/
WSRESTFUL CLIENTES DESCRIPTION "Servi�o REST CRUD de Clientes"

WSDATA RECEIVE As String //Json Recebido no corpo da requi��o
WSDATA CGC	   As String //Em caso de PUT ou DELETE pega o CGC por URL
 
WSMETHOD POST 	DESCRIPTION "Cadastra um novo cliente" 		WSSYNTAX ""
WSMETHOD GET  	DESCRIPTION "Retorna lista de clientes" 	WSSYNTAX ""
WSMETHOD PUT  	DESCRIPTION "Altera um cliente" 			WSSYNTAX "/CLIENTES || /CLIENTES/{CGC}"
 
END WSRESTFUL

/*/{Protheus.doc} GET
Retorna uma lista de clientes.
@author Victor Andrade
@since 28/04/2017
@type function
/*/
WSMETHOD GET WSSERVICE CLIENTES

Local aArea 	 := GetArea()
Local cNextAlias := GetNextAlias()
Local oCliente	 := CLIENTES():New() // --> Objeto da classe cliente
Local oResponse  := FULL_CLIENTES():New() // --> Objeto que ser� serializado
Local cJSON		 := ""
Local lRet		 := .T.

::SetContentType("application/json")

BeginSQL Alias cNextAlias
	SELECT A1_COD, A1_LOJA, A1_NOME, A1_END, A1_CGC, A1_CEP, A1_DDD, A1_TEL
	FROM %table:SA1% SA1
	WHERE SA1.%notdel%
EndSQL

(cNextAlias)->( DbGoTop() )

If (cNextAlias)->( !Eof() )

	While (cNextAlias)->( !Eof() )
		
		oCliente:SetCodigo( AllTrim((cNextAlias)->A1_COD ))
		oCliente:SetLoja( 	AllTrim((cNextAlias)->A1_LOJA))
		oCliente:SetNome( 	AllTrim((cNextAlias)->A1_NOME))
		oCliente:SetCGC( 	AllTrim((cNextAlias)->A1_CGC ))
		oCliente:SetCEP( 	AllTrim((cNextAlias)->A1_CEP ))
		oCliente:SetEnd( 	AllTrim((cNextAlias)->A1_END ))
		oCliente:SetDDD( 	AllTrim((cNextAlias)->A1_DDD ))
		oCliente:SetTel(	AllTrim((cNextAlias)->A1_TEL ))
		
		oResponse:Add(oCliente)
		
		(cNextAlias)->( DbSkip() )
	
	EndDo
	
	cJSON := FWJsonSerialize(oResponse, .T., .T.,,.F.)
	::SetResponse(cJSON)
		
Else
	SetRestFault(400, "SA1 Empty")
	lRet := .F.
EndIf

RestArea(aArea)

Return(lRet)

/*/{Protheus.doc} POST
Efetua a inclus�o de um novo cliente
@author Victor Andrade
@since 27/04/2017
@version undefined
@type function
/*/
WSMETHOD POST WSRECEIVE RECEIVE WSSERVICE CLIENTES

Local cJSON 	 := Self:GetContent() // Pega a string do JSON 
Local oParseJSON := Nil 
Local aDadosCli	 := {} //--> Array para ExecAuto do MATA030
Local cJsonRet   := ""
Local cArqLog	 := ""
Local cErro		 := ""
Local cCodSA1	 := ""
Local lRet		 := .T.
Local aArea		 := GetArea()

Private lMsErroAuto := .F.

// --> Cria o diret�rio para salvar os arquivos de log
If !ExistDir("\log_cli")
	MakeDir("\log_cli")
EndIf

::SetContentType("application/json")

// --> Deserializa a string JSON
FWJsonDeserialize(cJson, @oParseJSON)

SA1->( DbSetOrder(3) )
If !(SA1->( DbSeek( xFilial("SA1") + oParseJSON:CLIENTE:CGC ) ))

	cCodSA1 := GetNewCod()
	Aadd(aDadosCli, {"A1_FILIAL"	, xFilial("SA1")										, Nil} )				 
	Aadd(aDadosCli, {"A1_COD"		, cCodSA1												, Nil} )
	Aadd(aDadosCli, {"A1_LOJA"		, "01"													, Nil} )
	Aadd(aDadosCli, {"A1_CGC"		, oParseJSON:CLIENTE:CGC								, Nil} )
	Aadd(aDadosCli, {"A1_NOME"		, oParseJSON:CLIENTE:NOME								, Nil} )
	Aadd(aDadosCli, {"A1_NREDUZ"	, oParseJSON:CLIENTE:NOME								, Nil} )
	Aadd(aDadosCli, {"A1_END"		, oParseJSON:CLIENTE:ENDERECO							, Nil} )
	Aadd(aDadosCli, {"A1_PESSOA"	, Iif(Len(oParseJSON:CLIENTE:CGC) == 11, "F", "J")	 	, Nil} )
	Aadd(aDadosCli, {"A1_CEP"		, oParseJSON:CLIENTE:CEP								, Nil} )
	Aadd(aDadosCli, {"A1_TIPO"		, "F"													, Nil} )
	Aadd(aDadosCli, {"A1_EST"		, oParseJSON:CLIENTE:ESTADO								, Nil} )
	Aadd(aDadosCli, {"A1_MUN"		, oParseJSON:CLIENTE:MUNICIPIO							, Nil} )
	Aadd(aDadosCli, {"A1_TEL"		, oParseJSON:CLIENTE:TELEFONE							, Nil} )
	
	MsExecAuto({|x,y| MATA030(x,y)}, aDadosCli, 3) 
	
	If lMsErroAuto
		cArqLog := oParseJSON:CLIENTE:CGC + " - " + SubStr( Time(),1,5 ) + ".log"
		RollBackSX8()
		cErro := MostraErro("\log_cli", cArqLog)
		cErro := TrataErro(cErro) // --> Trata o erro para devolver para o client.
		SetRestFault(400, cErro)
		lRet := .F. 				
	Else
		ConfirmSX8()
		cJSONRet := '{"cod_cli":"' + SA1->A1_COD	+ '"';
	 				+ ',"loja":"'  + SA1->A1_LOJA 	+ '"';
	 				+ ',"msg":"'  + "Sucesso" 		+ '"';
	 				+'}'
	 				
	    ::SetResponse( cJSONRet )				
	EndIf		 

Else
	SetRestFault(400, "Cliente j� cadastrado: " + SA1->A1_COD + " - " + SA1->A1_LOJA)
	lRet := .F. 	 
EndIf

RestArea(aArea)

Return(lRet)

/*/{Protheus.doc} PUT
Altera as informa��es de um cliente
@author Victor Andrade
@since 28/04/2017
@type function
/*/
WSMETHOD PUT WSRECEIVE RECEIVE WSSERVICE CLIENTES

Local cJSON := Self:GetContent() // --> Pega a string do JSON
Local cCGC	:= Self:CGC // --> Pega o par�metro recebido pela UR�
Local lRet  := .T.
Local oParseJSON := Nil 
Local aDadosCli	 := {} //--> Array para ExecAuto do MATA030
Local cJsonRet   := ""
Local cArqLog	 := ""
Local cErro		 := ""
Local aArea		 := GetArea()

Private lMsErroAuto := .F.

If !ExistDir("\log_cli")
	MakeDir("\log_cli")
EndIf

::SetContentType("application/json")

// --> Deserializa a string JSON
FWJsonDeserialize(cJson, @oParseJSON)

SA1->( DbSetOrder(3) )
If (SA1->( DbSeek( xFilial("SA1") + cCGC ) ))
	
	Aadd( aDadosCli, {"A1_NOME", oParseJSON:CLIENTE:NOME 	 , Nil } )
	Aadd( aDadosCli, {"A1_END" , oParseJSON:CLIENTE:ENDERECO , Nil } )
	
	MsExecAuto({|x,y| MATA030(x,y)}, aDadosCli, 4) 
	
	If lMsErroAuto
		cArqLog := oParseJSON:CLIENTE:CGC + " - " + SubStr( Time(),1,5 ) + ".log"
		cErro := MostraErro("\log_cli", cArqLog)
		cErro := TrataErro(cErro) // --> Trata o erro para devolver para o client.
		SetRestFault(400, cErro)
		lRet := .F.
	Else
		cJSONRet := '{"cod_cli":"' + SA1->A1_COD	+ '"';
	 				+ ',"loja":"'  + SA1->A1_LOJA 	+ '"';
	 				+ ',"msg":"'   + "Alterado" 	+ '"';
	 				+'}'
	    ::SetResponse( cJSONRet )				
	EndIf		 
	
Else
	SetRestFault(400, "Cliente n�o encontrado.")
	lRet := .F.
EndIf

RestArea(aArea)

Return(lRet)

/*/{Protheus.doc} TrataErro
Trata o erro para devolver no JSON
@author Victor Andrade
@since 28/04/2017
@type function
/*/
Static Function TrataErro(cErroAuto)

Local nLines   := MLCount(cErroAuto)
Local cNewErro := ""
Local nErr	   := 0

For nErr := 1 To nLines
	cNewErro += AllTrim( MemoLine( cErroAuto, , nErr ) ) + " - "
Next nErr

Return(cNewErro)

/*/{Protheus.doc} GetNewCod
Retorna o pr�ximo c�digo livre do SA1
@author Victor Andrade
@since 28/04/2017
@type function
/*/
Static Function GetNewCod()

Local cCod  := GetSX8Num("SA1", "A1_COD")
Local aArea := GetArea()

SA1->( DbSetOrder(1) )

While SA1->( DbSeek( xFilial("SA1") + cCod ) )
	cCod := GetSX8Num("SA1", "A1_COD")
EndDo

RestArea(aArea)

Return(cCod)