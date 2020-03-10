<#
.Description
Measures Trello backlog board for completeness. A good backlog is DEEP: Detailed, Estimated, Emergent and Prioritized.

Detailed: Has description. TODO: Check for certain qualities or length.
Estimated: Has milestones and title has effort estimate (num)
Emergent: Items should be reviewed and updated regularly during grooming. # Cards Active within X days
Prioritized: Implicit in card lists. Unmeasured.
#>
param(
	[string]$BoardId,
	[int]$CardAge = 30
)

$cards = Get-TrelloBoardCards -BoardId $boardid

if($null -eq $cards) { return }

$numCards = $cards.Count

$numDetailed = $cards |Where-Object {$_.desc -ne ''} | Measure-Object
$numMilestones = $cards |Where-Object {$_.badges.checkItems -gt 0} | Measure-Object
$numEstimated = $cards |Where-Object {$_.title -match "\(\d+\)"} | Measure-Object

$cutoffDate = [datetime]::Now.AddDays(-$CardAge)
$numActive = $cards |Where-Object {([datetime]$_.dateLastActivity) -gt $cutoffDate}

$boardStats = [pscustomobject]@{
	TotalItems = $numCards
	Detailed = $numDetailed.Count
	Estimated = $numEstimated.Count
	Milestones = $numMilestones.Count
	Active = $numActive.Count
}

$boardStats