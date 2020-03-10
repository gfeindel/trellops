<#
.Description
Export cards from the given board, parsing backlog metadata.
#>
param(
    [string]$BoardId
)

$lists = Get-TrelloBoardLists -BoardId $BoardId

$lists |% {
    $cards = Get-TrelloListCards -ListId $_.id

    foreach($card in $cards) {
        $d = [datetime]::MinValue

        if($card.due) {
            $d = [datetime]($card.due)
        }
        $o = [pscustomobject]@{
            Name = $card.Name
            Due = $d.ToShortDateString()
            Sprint = $d.Month
            List = $_.Name
            Effort = 0
            Priority = 0
        }
        if($card.name -match "\(\d+\)") {
            $o.Effort = [int](($card.Name | Select-String -Pattern "\((\d+)\)").Matches[0].Groups[1].Value)
        }
        if($card.name -match "#\d+") {
            $o.Priority = [int](($card.Name | Select-String -Pattern "#(\d+)").Matches[0].Groups[1].Value)
        }
        $o
    }
}