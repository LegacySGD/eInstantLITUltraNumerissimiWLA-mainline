<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
var debugFeed = [];
var debugFlag = false;
// Format instant win JSON results.
// @param jsonContext String JSON results to parse and display.
// @param translation Set of Translations for the game.
function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc) {
    var scenario = getScenario(jsonContext);
    var scenarioWinNums = scenario.split('|')[0].split(',');
    var scenarioMultipliers = scenario.split('|')[1].split(',');
    var scenarioPrizes = scenario.split('|')[2].split(',');
    var scenarioGameNums = scenario.split('|').slice(3, -1);
    var scenarioBonusGame = scenario.split('|').slice(-1).join('').split(',');
    var convertedPrizeValues = (prizeValues.substring(1)).split('|').map(function (item) { return item.replace(/\t|\r|\n/gm, "") });
    var prizeNames = (prizeNamesDesc.substring(1)).split(',');

    ////////////////////
    // Parse scenario //
    ////////////////////

    const winNumPerRow = [4, 3, 2, 1, 1, 1, 1, 1, 1, 2, 3, 4];

    var arrBonus = [];
    var arrGameNums = [];
    var arrGameRow = [];
    var arrGames = [];
    var arrMultipliers = [];
    var arrPrizes = [];
    var arrWinNumRows = [];
    var arrWinNums = [];
    var countWinNum = -1;
    var objBonus = {};
    var objGameNum = {};
    var objMultiplier = {};
    var objPrize = {};
    var objWinNum = {};

    for (var indexWinNumRow = 0; indexWinNumRow < winNumPerRow.length; indexWinNumRow++) {
        arrWinNums = [];

        for (var indexWinNum = 0; indexWinNum < winNumPerRow[indexWinNumRow]; indexWinNum++) {
            countWinNum++;

            objWinNum = { sValue: '', bMatched: false };

            objWinNum.sValue = scenarioWinNums[countWinNum].replace(new RegExp('[*]', 'g'), '');
            objWinNum.bMatched = (scenarioWinNums[countWinNum][0] == '*');

            arrWinNums.push(objWinNum);
        }

        arrWinNumRows.push(arrWinNums);
    }

    for (var indexMultiplier = 0; indexMultiplier < scenarioMultipliers.length; indexMultiplier++) {
        objMultiplier = { sValue: '', bMatched: false };

        objMultiplier.sValue = scenarioMultipliers[indexMultiplier].replace(new RegExp('[*]', 'g'), '');
        objMultiplier.bMatched = (scenarioMultipliers[indexMultiplier][0] == '*');

        arrMultipliers.push(objMultiplier);
    }

    for (var indexPrize = 0; indexPrize < scenarioPrizes.length; indexPrize++) {
        objPrize = { sValue: '', bMatched: false };

        objPrize.sValue = scenarioPrizes[indexPrize].replace(new RegExp('[*]', 'g'), '');
        objPrize.bMatched = (scenarioPrizes[indexPrize][0] == '*');

        arrPrizes.push(objPrize);
    }

    for (var indexGame = 0; indexGame < scenarioGameNums.length; indexGame++) {
        arrGameRow = scenarioGameNums[indexGame].split(',');
        arrGameNums = [];

        for (var indexGameNum = 0; indexGameNum < arrGameRow.length; indexGameNum++) {
            objGameNum = { sValue: '', bMatched: false };

            objGameNum.sValue = arrGameRow[indexGameNum].replace(new RegExp('[*]', 'g'), '');
            objGameNum.bMatched = (arrGameRow[indexGameNum][0] == '*');

            arrGameNums.push(objGameNum);
        }

        arrGames.push(arrGameNums);
    }

    for (var indexBonus = 0; indexBonus < scenarioBonusGame.length; indexBonus++) {
        objBonus = { sSymbol: '', bMatched: false };

        objBonus.sSymbol = scenarioBonusGame[indexBonus].replace(new RegExp('[*]', 'g'), '').split('_')[0];
        objBonus.bMatched = (scenarioBonusGame[indexBonus][0] == '*');

        arrBonus.push(objBonus);
    }

    /////////////////////////
    // Currency formatting //
    /////////////////////////

    var bCurrSymbAtFront = false;
    var strCurrSymb = '';
    var strDecSymb = '';
    var strThouSymb = '';

    function getCurrencyInfoFromTopPrize() {
        var topPrize = convertedPrizeValues[0];
        var strPrizeAsDigits = topPrize.replace(new RegExp('[^0-9]', 'g'), '');
        var iPosFirstDigit = topPrize.indexOf(strPrizeAsDigits[0]);
        var iPosLastDigit = topPrize.lastIndexOf(strPrizeAsDigits.substr(-1));
        bCurrSymbAtFront = (iPosFirstDigit != 0);
        strCurrSymb = (bCurrSymbAtFront) ? topPrize.substr(0, iPosFirstDigit) : topPrize.substr(iPosLastDigit + 1);
        var strPrizeNoCurrency = topPrize.replace(new RegExp('[' + strCurrSymb + ']', 'g'), '');
        var strPrizeNoDigitsOrCurr = strPrizeNoCurrency.replace(new RegExp('[0-9]', 'g'), '');
        strDecSymb = strPrizeNoDigitsOrCurr.substr(-1);
        strThouSymb = (strPrizeNoDigitsOrCurr.length > 1) ? strPrizeNoDigitsOrCurr[0] : strThouSymb;
    }

    function getPrizeInCents(AA_strPrize) {
        return parseInt(AA_strPrize.replace(new RegExp('[^0-9]', 'g'), ''), 10);
    }

    function getCentsInCurr(AA_iPrize) {
        var strValue = AA_iPrize.toString();

        strValue = (strValue.length < 3) ? ('00' + strValue).substr(-3) : strValue;
        strValue = strValue.substr(0, strValue.length - 2) + strDecSymb + strValue.substr(-2);
        strValue = (strValue.length > 6) ? strValue.substr(0, strValue.length - 6) + strThouSymb + strValue.substr(-6) : strValue;
        strValue = (bCurrSymbAtFront) ? strCurrSymb + strValue : strValue + strCurrSymb;

        return strValue;
    }

    getCurrencyInfoFromTopPrize();

    ///////////////
    // UI Config //
    ///////////////

    const colourBlack = '#000000';
    const colourBlue = '#99ccff';
    const colourBrown = '#990000';
    const colourGreen = '#00cc00';
    const colourLemon = '#ffff99';
    const colourLilac = '#ccccff';
    const colourLime = '#ccff99';
    const colourNavy = '#0000ff';
    const colourOrange = '#ffcc99';
    const colourPink = '#ffccff';
    const colourPurple = '#cc99ff';
    const colourRed = '#ff9999';
    const colourScarlet = '#ff0000';
    const colourWhite = '#ffffff';
    const colourYellow = '#ffff00';

    const boxHeightStd = 24;
    const boxWidth = 120;
    const boxMargin = 1;
    const circleSize = 60;

    var boxColourStr = '';
    var canvasIdStr = '';
    var elementStr = '';
    var textStr1 = '';

    var r = [];

    function showBox(A_strCanvasId, A_strCanvasElement, A_iWidth, A_iHeight, A_strBoxColour, A_strTextColour, A_strText1) {
        var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
        var canvasWidth = A_iWidth + 2 * boxMargin;
        var canvasHeight = A_iHeight + 2 * boxMargin;
        var boxTextY = A_iHeight / 2 + 3;
        var textSize1 = ((A_strBoxColour == colourBlack) ? '14' : '16');

        r.push('<canvas id="' + A_strCanvasId + '" width="' + canvasWidth.toString() + '" height="' + canvasHeight.toString() + '"></canvas>');
        r.push('<script>');
        r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
        r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
        r.push(canvasCtxStr + '.font = "bold ' + textSize1 + 'px Arial";');
        r.push(canvasCtxStr + '.textAlign = "center";');
        r.push(canvasCtxStr + '.textBaseline = "middle";');
        r.push(canvasCtxStr + '.strokeRect(' + (boxMargin + 0.5).toString() + ', ' + (boxMargin + 0.5).toString() + ', ' + A_iWidth.toString() + ', ' + A_iHeight.toString() + ');');
        r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
        r.push(canvasCtxStr + '.fillRect(' + (boxMargin + 1.5).toString() + ', ' + (boxMargin + 1.5).toString() + ', ' + (A_iWidth - 2).toString() + ', ' + (A_iHeight - 2).toString() + ');');
        r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
        r.push(canvasCtxStr + '.fillText("' + A_strText1 + '", ' + (A_iWidth / 2 + boxMargin).toString() + ', ' + boxTextY.toString() + ');');
        r.push('</script>');
    }

    function showCircle(A_strCanvasId, A_strCanvasElement, A_strBoxColour, A_strText) {
        var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
        var canvasSize = circleSize + 2 * boxMargin;
        var circleOrigin = canvasSize / 2;
        var circleRadius = circleSize / 2;

        r.push('<canvas id="' + A_strCanvasId + '" width="' + canvasSize.toString() + '" height="' + canvasSize.toString() + '"></canvas>');
        r.push('<script>');
        r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
        r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
        r.push(canvasCtxStr + '.font = "bold 16px Arial";');
        r.push(canvasCtxStr + '.textAlign = "center";');
        r.push(canvasCtxStr + '.textBaseline = "middle";');
        r.push(canvasCtxStr + '.beginPath();');
        r.push(canvasCtxStr + '.arc(' + circleOrigin.toString() + ', ' + circleOrigin.toString() + ', ' + circleRadius.toString() + ', 0, 2*Math.PI);');
        r.push(canvasCtxStr + '.stroke();');
        r.push(canvasCtxStr + '.arc(' + circleOrigin.toString() + ', ' + circleOrigin.toString() + ', ' + (circleRadius - 1).toString() + ', 0, 2*Math.PI);');
        r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
        r.push(canvasCtxStr + '.fill();');
        r.push(canvasCtxStr + '.fillStyle = "' + colourBlack + '";');
        r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + (circleRadius + boxMargin).toString() + ', ' + (circleRadius + 3).toString() + ');');

        r.push('</script>');
    }

    ///////////////
    // Main Game //
    ///////////////

    const multiRows = [3, 0, 0, 2, 0, 2, 0, 2, 0, 3, 0, 0];
    const totalNumCols = 7;

    var countBlank = 0;
    var countMulti = -1;

    r.push('<p>' + getTranslationByName("gameDetails", translations) + '</p>');

    r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
    r.push('<tr class="tableheader">');
    r.push('<td colspan="' + winNumPerRow[0].toString() + '" align="center">');

    canvasIdStr = 'cvsWinNumsTitle';
    elementStr = 'eleWinNumsTitle';
    textStr1 = getTranslationByName("titleWinNums", translations);

    showBox(canvasIdStr, elementStr, winNumPerRow[0] * circleSize, boxHeightStd, colourBlack, colourWhite, textStr1);

    r.push('</td>');
    r.push('<td colspan="' + (totalNumCols - winNumPerRow[0]).toString() + '" align="center">');
    r.push('</td>');
    r.push('<td align="center">');

    canvasIdStr = 'cvsPrizeTitle';
    elementStr = 'elePrizeTitle';
    textStr1 = getTranslationByName("titlePrize", translations);

    showBox(canvasIdStr, elementStr, boxWidth, boxHeightStd, colourBlack, colourWhite, textStr1);

    r.push('</td>');
    r.push('<td align="center">');
    r.push('</td>');
    r.push('<td align="center">');

    canvasIdStr = 'cvsMultiTitle';
    elementStr = 'eleMultiTitle';
    textStr1 = getTranslationByName("titleMulti", translations);

    showBox(canvasIdStr, elementStr, boxWidth, boxHeightStd, colourBlack, colourWhite, textStr1);

    r.push('</td>');
    r.push('</tr>');

    for (var indexWinNumRow = 0; indexWinNumRow < arrWinNumRows.length; indexWinNumRow++) {
        r.push('<tr class="tablebody">');

        for (var indexWinNum = 0; indexWinNum < arrWinNumRows[indexWinNumRow].length; indexWinNum++) {
            r.push('<td align="center">');

            canvasIdStr = 'cvsWinNumData' + indexWinNumRow.toString() + '_' + indexWinNum.toString();
            elementStr = 'eleWinNumData' + indexWinNumRow.toString() + '_' + indexWinNum.toString();
            boxColourStr = (arrWinNumRows[indexWinNumRow][indexWinNum].bMatched) ? colourLime : colourWhite;
            textStr1 = arrWinNumRows[indexWinNumRow][indexWinNum].sValue;

            showCircle(canvasIdStr, elementStr, boxColourStr, textStr1);

            r.push('</td>');
        }

        countBlank = totalNumCols - arrWinNumRows[indexWinNumRow].length - arrGames[indexWinNumRow].length;

        for (var indexBlank = 0; indexBlank < countBlank; indexBlank++) {
            r.push('<td align="center">');
            r.push('</td>');
        }

        for (var indexGameNum = 0; indexGameNum < arrGames[indexWinNumRow].length; indexGameNum++) {
            r.push('<td align="center">');

            canvasIdStr = 'cvsGameNumData' + indexWinNumRow.toString() + '_' + indexGameNum.toString();
            elementStr = 'eleGameNumData' + indexWinNumRow.toString() + '_' + indexGameNum.toString();
            boxColourStr = (arrGames[indexWinNumRow][indexGameNum].bMatched) ? colourLime : colourWhite;
            textStr1 = arrGames[indexWinNumRow][indexGameNum].sValue;

            showCircle(canvasIdStr, elementStr, boxColourStr, textStr1);

            r.push('</td>');
        }

        r.push('<td align="center">');

        canvasIdStr = 'cvsPrizeData' + indexWinNumRow.toString();
        elementStr = 'elePrizeData' + indexWinNumRow.toString();
        boxColourStr = (arrPrizes[indexWinNumRow].bMatched) ? colourLime : colourWhite;
        textStr1 = convertedPrizeValues[getPrizeNameIndex(prizeNames, arrPrizes[indexWinNumRow].sValue)];

        showBox(canvasIdStr, elementStr, boxWidth, 3 * boxHeightStd, boxColourStr, colourBlack, textStr1);

        r.push('</td>');
        r.push('<td align="center">');

        canvasIdStr = 'cvsGameData' + indexWinNumRow.toString();
        elementStr = 'eleGameData' + indexWinNumRow.toString();
        textStr1 = getTranslationByName("titleGame", translations) + ' ' + (indexWinNumRow + 1).toString();

        showBox(canvasIdStr, elementStr, boxWidth, boxHeightStd, colourBlack, colourWhite, textStr1);

        r.push('</td>');

        if (multiRows[indexWinNumRow] != 0) {
            r.push('<td rowspan="' + multiRows[indexWinNumRow].toString() + '" align="center">');

            countMulti++;
            canvasIdStr = 'cvsMultiData' + countMulti.toString();
            elementStr = 'eleMultiData' + countMulti.toString();
            boxColourStr = (arrMultipliers[countMulti].bMatched) ? colourLime : colourWhite;
            textStr1 = 'X' + arrMultipliers[countMulti].sValue;

            showBox(canvasIdStr, elementStr, boxWidth, multiRows[indexWinNumRow] * 3 * boxHeightStd, boxColourStr, colourBlack, textStr1);

            r.push('</td>');
        }

        r.push('</tr>');
    }

    r.push('</table>');

    ////////////////
    // Bonus Game //
    ////////////////

    const bonusPrizes = ['K', 'J', 'I'];

    r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
    r.push('<tr class="tableheader">');
    r.push('<td colspan="3" align="center">');

    canvasIdStr = 'cvsBonusGameTitle';
    elementStr = 'eleBonusGameTitle';
    textStr1 = getTranslationByName("titleBonusGame", translations);

    showBox(canvasIdStr, elementStr, 3 * boxWidth, boxHeightStd, colourBlack, colourWhite, textStr1);

    r.push('</td>');
    r.push('</tr>');
    r.push('<tr class="tablebody">');

    for (var indexBonus = 0; indexBonus < arrBonus.length; indexBonus++) {
        r.push('<td align="center">');

        canvasIdStr = 'cvsBonusPrizeTitle' + indexBonus.toString();
        elementStr = 'eleBonusPrizeTitle' + indexBonus.toString();
        textStr1 = convertedPrizeValues[getPrizeNameIndex(prizeNames, bonusPrizes[indexBonus])];

        showBox(canvasIdStr, elementStr, boxWidth, boxHeightStd, colourBlack, colourWhite, textStr1);

        r.push('</td>');
    }

    r.push('</tr>');
    r.push('<tr class="tablebody">');

    for (var indexBonus = 0; indexBonus < arrBonus.length; indexBonus++) {
        r.push('<td align="center">');

        canvasIdStr = 'cvsBonusPrizeData' + indexBonus.toString();
        elementStr = 'eleBonusPrizeData' + indexBonus.toString();
        boxColourStr = (arrBonus[indexBonus].bMatched) ? colourLime : colourWhite;
        textStr1 = arrBonus[indexBonus].sSymbol;

        showBox(canvasIdStr, elementStr, boxWidth, boxHeightStd, boxColourStr, colourBlack, textStr1);

        r.push('</td>');
    }

    r.push('</tr>');
    r.push('</table>');

    r.push('<p>&nbsp;</p>');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						if(debugFlag)
						{
							//////////////////////////////////////
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
	 							r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");

						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
