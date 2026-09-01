param(
	[string]$Saida = (Join-Path $PSScriptRoot "..\ideias\referencia_digimon_heroes\colecao_cartas.csv")
)

$ErrorActionPreference = "Stop"
$paginas = [ordered]@{
	Dragon = "Digimon Heroes!/Collection/Dragon"
	Knight = "Digimon Heroes!/Collection/Knight"
	Nature = "Digimon Heroes!/Collection/Nature"
	Dark = "Digimon Heroes!/Collection/Dark"
	Holy = "Digimon Heroes!/Collection/Holy"
}

$campos = @(
	"element", "name", "card_name", "card", "rarity", "max_lv", "cost",
	"atk", "defense", "hp", "support", "main_race", "secondary_race",
	"generation", "main_skill", "main_skill_turns", "leader_skill",
	"leader_skill_turns", "source_page"
)

$cartas = [System.Collections.Generic.List[object]]::new()
foreach ($elemento in $paginas.Keys) {
	$pagina = $paginas[$elemento]
	$paginaCodificada = [uri]::EscapeDataString($pagina)
	$uri = "https://digimon.fandom.com/api.php?action=parse&page=$paginaCodificada&prop=wikitext&format=json&formatversion=2&origin=*"
	$resposta = Invoke-RestMethod -Uri $uri -Headers @{
		"User-Agent" = "1BitHeroesResearch/0.1"
	}
	$wikitext = $resposta.parse.wikitext
	foreach ($match in [regex]::Matches($wikitext,
			'(?s)\{\{Card Infobox DH-DM\s*(.*?)\}\}')) {
		$dados = [ordered]@{ element = $elemento }
		foreach ($linha in ($match.Groups[1].Value -split "`n")) {
			if ($linha -match '^\s*\|\s*([^=]+?)\s*=\s*(.*?)\s*$') {
				$dados[$matches[1].Trim()] = $matches[2].Trim()
			}
		}
		$dados["source_page"] = "https://digimon.fandom.com/wiki/" +
			([uri]::EscapeDataString($pagina) -replace "%2F", "/")
		$linhaCsv = [ordered]@{}
		foreach ($campo in $campos) {
			$linhaCsv[$campo] = if ($dados.Contains($campo)) { $dados[$campo] } else { "" }
		}
		$cartas.Add([pscustomobject]$linhaCsv)
	}
}

$destino = [System.IO.Path]::GetFullPath($Saida)
$pasta = Split-Path -Parent $destino
[System.IO.Directory]::CreateDirectory($pasta) | Out-Null
$cartas | Sort-Object element, card | Export-Csv -LiteralPath $destino -NoTypeInformation -Encoding utf8

Write-Output "Registros extraidos: $($cartas.Count)"
Write-Output "Destino: $destino"
Write-Output "Fonte: DigimonWiki/Fandom, conteudo comunitario CC BY-SA salvo indicacao contraria."
