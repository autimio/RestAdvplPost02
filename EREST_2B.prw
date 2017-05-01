#Include 'protheus.ch'
#Include 'parmtype.ch'

/*/{Protheus.doc} EREST_2B
__Dummy function
@author Victor Andrade
@since 25/04/2017
@version undefined

@type function
/*/
User Function EREST_2B()	
Return

Class FULL_CLIENTES
	
	Data Clientes
	
	Method New() Constructor
	Method Add() 
	
EndClass

/*/{Protheus.doc} New
M�todo contrutor
@author Victor Andrade
@since 25/04/2017
@type function
/*/
Method New() Class FULL_CLIENTES
	::Clientes := {}
Return(Self)

/*/{Protheus.doc} Add	
Adiciona um novo objeto de cliente
@author Victor Andrade
@since 25/04/2017
@param oCliente, object, Objeto da Classe Clientes
@type function
/*/
Method Add(oCliente) Class FULL_CLIENTES
	Aadd(::Clientes, oCliente)
Return