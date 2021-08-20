<#
.Description
Export cards from the given board, parsing backlog metadata.
#>
param(
    [string]$BoardId
)

$lists = Get-TrelloBoardLists -BoardId $BoardId
$unixEpoch = [datetime]'1/1/1970 12:00am'

$lists |% {
    $cards = Get-TrelloListCards -ListId $_.id -Members

    foreach($card in $cards) {
        $d = [datetime]::MinValue

        if($card.due) {
            $d = [datetime]($card.due)
        }
        $o = [pscustomobject]@{
            Id = $card.id
            Name = $card.Name
            Description = $card.desc
            List = $_.Name
            Labels = ""
            Members = ""
            Created = ($unixEpoch.AddSeconds([Convert]::ToInt64($card.id.Substring(0,8),16))).ToLocalTime()
            LastActivity = [datetime]($card.dateLastActivity)
        }
        if($card.labels) {
            $o.Labels = [string]::Join(',',$card.labels.name)
        }
        if($card.members) {
            $o.Members = [string]::Join(',',$card.members.initials)
        }
        if($card.name -match "\(\d+\)") {
            $o.Effort = [int](($card.Name | Select-String -Pattern "\((\d+)\)").Matches[0].Groups[1].Value)
        }
        #if($card.labels -match "#\d+") {
        #    $o.Priority = [int](($card.Name | Select-String -Pattern "#(\d+)").Matches[0].Groups[1].Value)
        #}
        $o
    }
}