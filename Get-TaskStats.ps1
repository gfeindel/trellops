<#
.Description
Retrieves cards from the specified 'Done' list and calculates duration of each. 
.Notes
Tasks:
Queue time: Time(Ready,Doing). Time task spent in queue but not started yet.
Flow time: Time(Ready,Done). Total time from entered queue to completed.
  This is most valuable. We expect all tasks to be <1day. Dependencies and unplanned work will
  increase flow time and add high variability (uncertainty). Best metric to argue against gantt charts.
Cycle time: Time(Doing,Done). Total time from work started to completed.
Hold time: Time(Blocked/Waiting). Total time spent in waiting state. Must figure out how to measure using action history.

Objectives:
Time(SprintStart,Done), bucket by storypoints value
#>
param(
    [string]$ReadyListId,
    [string]$DoingListId,
    [string]$DoneListId,
    [string]$WaitingListId
)

$doneCards = Get-TrelloListCards -ListId $DoneListId
$unixEpoch = [datetime]'1/1/1970 12:00am'

$doneCards |Foreach-Object {
    $actions = Get-TrelloActions -CardId $_.id

    $o = [pscustomobject]@{
        Id = $_.id
        Name = $_.name
        WorkType = ""
        # First 8 chars of ID are Unix timestamp in hex of card creation
        Created = ($unixEpoch.AddSeconds([Convert]::ToInt64($_.id.Substring(0,8),16))).ToLocalTime()
        DoneDate = [datetime]::MinValue
        QueueTime = 0
        FlowTime = 0
        CycleTime = 0
    }

    $label = $_.labels |Where-Object{$_.name -eq 'Unplanned'}
    if($label) {
        $o.WorkType = 'Unplanned'
    } else {
        $o.WorkType = 'Planned'
    }

    # Card is "Done" when it was last moved to the Done list.
    $doingAction = $actions |
                Where-Object{$_.type -eq 'updateCard' -and $_.data.listAfter.id -eq $DoingListId} | 
                Select-Object -First 1
    $doneAction = $actions |
                Where-Object{$_.type -eq 'updateCard' -and $_.data.listAfter.id -eq $DoneListId} | 
                Select-Object -First 1
    # Wait time:
    # Add dates of "move from wait" actions and subtract dates of "move to wait"
    # (B-A) + (D-C) = B+D-A-C
    if($doneAction) {
        $o.DoneDate = [datetime]($doneAction.date)
        $flowTime = New-TimeSpan -Start $o.Created -End $o.DoneDate
        $o.FlowTime = [int]($flowTime.TotalHours)

        if($doingAction) {
            $doingDate = [datetime]($doingAction.date)
            $queueTime = New-TimeSpan -Start $o.Created -End $doingDate
            $cycleTime = New-TimeSpan -Start $doingDate -End $o.DoneDate
            $o.QueueTime = [int]($queueTime.TotalHours)
            $o.CycleTime = [int]($cycleTime.TotalHours)
        } else {
            Write-Warning "Unable to calculate cycle time for $($_.id) $($_.name)."
        }        
    } else {
        Write-Warning "Unable to calculate flow time for $($_.id) $($_.name): done date information."
    }
    $o
}