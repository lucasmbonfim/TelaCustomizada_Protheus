#INCLUDE "Protheus.CH"
#INCLUDE "FWMVCDef.ch"
#INCLUDE "topconn.ch"

//Ponto de entrada - Documento de Entrada - Validação de itens inseridos
User Function MT100LOK()
    Local cQry := " "
    Private nPosRateio := aScan( aHeader, {|x| Upper(AllTrim(x[2])) == "D1_X_RAT" } ) //Pegando a posição do campo D1_X_RAT
    Private cPosItem    := aScan( aHeader, {|x| Upper(AllTrim(x[2])) == "D1_ITEM" } )   //ZRT_ITEMNF
    Private cPosDoc     := aScan( aHeader, {|x| Upper(AllTrim(x[2])) == "CNFISCAL" } )  //ZRT_DOC 
    Private cPosSerie   := aScan( aHeader, {|x| Upper(AllTrim(x[2])) == "CSERIE" } )    //ZRT_SERIE 
    Private cPosForn    := aScan( aHeader, {|x| Upper(AllTrim(x[2])) == "CA100FOR" } )  //ZRT_FORN
    Private cPosLoja    := aScan( aHeader, {|x| Upper(AllTrim(x[2])) == "CLOJA" } )     //ZRT_LOJA    
    Private lRetMT100  :=.T.
    Private cAUX := aCols[n,cPosItem]

    //Consulta SQL para verificar se já possui os dados no banco
    cQry := " SELECT * FROM ZRT990 (NOLOCK) WHERE ZRT_DOC = '"+CNFISCAL+"' AND ZRT_SERIE = '"+CSERIE+"' AND ZRT_FORN = '"+CA100FOR+"' AND ZRT_LOJA = '"+CLOJA+"' AND ZRT_ITEMNF = '"+cAUX+"' AND D_E_L_E_T_ <> '*' "
    TcQuery cQry New Alias "ZRX"

    //Teste para verificar se o campo D1_X_RAT está preenchido com Sim e se o ZRT_DOC está vazio. Se estiver, chama a função que monta a tela
    If Empty(ZRX->ZRT_DOC) .And. aCols[n,nPosRateio] == "S"
        lRetMT100 := u_zTelaR()    
    EndIf    
    
    ZRX->(DbCloseArea())

Return lRetMT100 

//Função para criar a tela que será chamada caso o campo Rateio estiver como "sim"
User Function zTelaR()                //nItem, cNumDoc, nNumSerie, cForNF,cLojaNF)
    Local aArea         := GetArea()
    Local aaCampos  	:= {"ZRT_PERC","ZRT_CODOR"} //Variável contendo o campo editável no Grid
    //Local lOk := .T.
    Local oSay1                       //Objeto para posicionar o texto na tela
    Private lRetZRT     := .T.        //Variável criado pelo Rafael ???
    Private oLista                    //Declarando o objeto do browser
    Private aCabecalho  := {}         //Variavel que montará o aHeader do grid
    Private aColsEx 	:= {}         //Variável que receberá os dados
    Private oFontSub    := TFont():New('Courier new',,-12,.T.)  
    Private nOpca       := 0 
    Private nJanLarg    := 700      //Largura da janela 
    Private nJanAltu    := 300      //Altura da janela 

    DEFINE MSDIALOG oDlg TITLE "Rateio por Orçamento" FROM 000, 000  TO nJanAltu, nJanLarg  COLORS 0, 16777215 PIXEL
        
        //Lin. Inicial | Col. Inicial SAY ....                                                                                                                            SIZE TAM. OBJETO, LARGURA
        @ 045, 005 SAY oSay1 PROMPT "Documento: " +CNFISCAL+Space(10)+" Item NF: " + aCols[n,cPosItem]+Space(10)+" Fornecedor: " +CA100FOR+Space(10)+ " Loja: " +CLOJA+"" SIZE 350, 025 COLORS CLR_BLACK FONT oFontSub OF oDlg PIXEL

        //Chamar a função que cria a estrutura do aHeader
        CriaCabec()
 
        //Monta o browser com inclusão, remoção e atualização                                 
        oLista := MsNewGetDados():New(055, 005, ;  //Linha Inicial e Coluna Inicial    
        (nJanAltu/2)-18, (nJanLarg/2), ;           //Altura da Janela e Largura    
         GD_INSERT+GD_DELETE+GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "AllwaysTrue", aACampos, , 999, "AllwaysTrue", " ", "AllwaysTrue", oDlg, aCabecalho, )

        /*
        Alinho o grid para ocupar todo o meu formulário
        oLista:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
        */
 
        //Ao abrir a janela o cursor está posicionado no meu objeto
        oLista:oBrowse:SetFocus()

        EnchoiceBar(oDlg, {|| nOpca := 1,oDlg:End() }, {|| ,oDlg:End() },,)

    ACTIVATE MSDIALOG oDlg CENTERED
    
    If nOpca := 1
        lRetZRT := u_GravaZRT() //Chama a função para gravar os registros 
    EndIf

    RestArea(aArea)
Return lRetZRT //Retorna .T. pós chamar a função para gravar os registros 

Static Function CriaCabec()
    Aadd(aCabecalho, {;
                  "% Rat.",;	    //X3Titulo()
                  "ZRT_PERC",;  	//X3_CAMPO
                  "@E 999.99",;		//X3_PICTURE
                  6,;			    //X3_TAMANHO
                  2,;			    //X3_DECIMAL
                  "",;			    //X3_VALID
                  "",;			    //X3_USADO
                  "N",;			    //X3_TIPO
                  "",;		        //X3_F3   
                  "R",;			    //X3_CONTEXT
                  "",;			    //X3_CBOX
                  "",;			    //X3_RELACAO
                  ""})			    //X3_WHEN
    Aadd(aCabecalho, {;
                  "Código",;	    //X3Titulo()
                  "ZRT_CODOR",;  	//X3_CAMPO
                  "@!",;		    //X3_PICTURE
                  10,;			    //X3_TAMANHO
                  0,;			    //X3_DECIMAL
                  "",;			    //X3_VALID
                  "",;			    //X3_USADO
                  "C",;			    //X3_TIPO
                  "ZOC_OR",;	    //X3_F3
                  "R",;			    //X3_CONTEXT
                  "",;			    //X3_CBOX
                  "",;			    //X3_RELACAO
                  ""})			    //X3_WHEN       

Return

//Função para gravar os registros da tela na tabela ZRT
User Function GravaZRT()
    Local aColsAux   := oLista:aCols
    Local _i         := 0 
    Private xlRet    := .T.
    Private nValPerc := 0 

    //Laço para somar os valores percentuais (total deve ser 100)
    For _i := 1 To Len(aColsAux)
        nValPerc += aColsAux[_i][1]
    Next 

    //Laço para pegar todas as linhas preenchidas    
    For _i := 1 To Len(aColsAux)
        //Teste para verificar se a soma dos percentuais (rateio é diferente de 100)
        If nValPerc != 100
            Alert("Valor do rateio diferente de 100!") 
            Return 
            xlRet := .F.
            Else 
                //Se o percentual for diferente de 0 e o código de orçamento for diferente de vazio, grava os registros
                If aColsAux[_i][1] <> 0 .And. aColsAux[_i][2] <> " "
                    DbSelectArea("ZRT")
                    //Gravando os registros na tabela ZRT
                    RecLock("ZRT", .T.)
                    ZRT->ZRT_FILIAL := xFilial("ZRT")
                    ZRT->ZRT_ITEMNF := aCols[n,cPosItem]
                    ZRT->ZRT_DOC    := CNFISCAL
                    ZRT->ZRT_SERIE  := CSERIE 
                    ZRT->ZRT_PERC   := aColsAux[_i][1]
                    ZRT->ZRT_CODOR  := aColsAux[_i][2]
                    ZRT->ZRT_FORN   := CA100FOR
                    ZRT->ZRT_LOJA   := CLOJA
                    MsUnlock("ZRT")
                EndIf
        EndIf
    Next 

Return xlRet //Retornará .T. se o valor rateado for igual a 100 e liberará a inclusão do próximo item na SD1
