<#
.Description
Retrieves cards from given list and formats status report based on title, description, progress and comments. Output is HTML report.
#>

param(
    [string]$ListId
)

$cards = Get-TrelloListCards -ListId $ListId -Members |Where-Object {$_.name -ne 'START HERE'}

$cards |ForEach-Object {

    $o = [pscustomobject]@{
        Title = $_.name
        Progress = "In Progress"
        Due = ""
        TeamMembers = ""
        Effort = 0
        Status = "No status update."
    }

    if($_.due) {
        $o.Due = ([datetime]($_.due)).ToShortDateString()
    }
    $o.TeamMembers = [string]::Join(', ',$_.members.initials)

    if([int]($_.badges.checkItems) -gt 0) {
        if($_.badges.checkItemsChecked -eq $_.badges.checkItems -or $_.dueComplete) {
            $o.Progress = "Complete"
        } else {
            $o.Progress = "$($_.badges.checkItemsChecked)/$($_.badges.checkItems)"
        }
    }

    if($_.name -match "\((\d+)\)") {
        $match = Select-String -InputObject $_.name -Pattern "\((\d+)\)"
        $o.Effort = [int]($match.Matches[0].Groups[1].Value)
    }

    # Retrieve and format comments for activity feed.
    $lastUpdate = Get-TrelloActions -CardId $_.id |Where-Object {$_.type -eq 'commentCard'} | Select-Object -First 1
    if($lastUpdate) {
        $d = ([datetime]($lastUpdate.date)).ToString("MM/dd")
        $o.Status = "${d} $($lastUpdate.data.text)"
    }
    $o
}