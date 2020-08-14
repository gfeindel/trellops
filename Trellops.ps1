[CmdletBinding()]

$script:trello_api_key = ""
$script:trello_api_token = ""

function Set-TrelloAuth {
    param(
        [string]$key,
        [string]$token
    )
    $script:trello_api_key = $key
    $script:trello_api_token = $token
}
function Get-TrelloAuth {
    $key = ""
    $token = ""
    if($null -ne $env:TRELLO_API_KEY) {
        $key = $env:TRELLO_API_KEY
    } else {
        $key = $script:trello_api_key
    }
    if($null -ne $env:TRELLO_API_TOKEN) {
        $token = $env:TRELLO_API_TOKEN
    } else {
        $token = $script:trello_api_token
    }
    "key=${key}&token=${token}"
}

function Invoke-TrelloApi {
    param(
        [parameter(Mandatory)]
        # The URI path following the base API URL.
        # Example: /boards/{boardid}
        [string]$apiCall,
        # URL-encoded Query parameters to follow ? in the URI. Do not include auth info.
        [string]$params = ""
    )
    $baseUri = 'https://api.trello.com/1'
    $auth = Get-TrelloAuth
    
    $uri = "${baseUri}${apiCall}?$auth"
    
    if($params) {
        $uri += "&$params"
    }

    Write-Verbose $uri

    $result = Invoke-RestMethod -Uri $uri -Method Get
    $result
}
function Get-TrelloActions {
    param(
        [parameter(ParameterSetName="Board")]
        [string]$BoardId,
        [parameter(ParameterSetName="Card")]
        [string]$CardId,
        [parameter(ParameterSetName="List")]
        [string]$ListId
        #To do: Add support for filtering by before/since
    )
    $uri = ""

    switch($PSCmdlet.ParameterSetName) {
        "Board" {
            $uri = "/boards/$BoardId/actions"
        }
        "Card" {
            $uri = "/cards/$CardId/actions"
        }
        "List" {
            $uri = "/lists/$ListId/actions"
        }
    }
    $result = Invoke-TrelloApi -apiCall $uri
    $result
}
function Get-TrelloBoards {
    param(
        [string]$BoardId
    )
    
    if($null -eq $BoardId -or $BoardId -eq '') {
        $uri = "/members/me/boards"
    } else {
        $uri = "/boards/${BoardId}"
    }

    $boards = Invoke-TrelloApi -apiCall $uri
    $boards
}

function Get-TrelloBoardLists {
    param(
        [parameter(Mandatory)]
        [string]$BoardId
    )
    
    $lists = Invoke-TrelloApi -apiCall "/boards/${BoardId}/lists"
    $lists
}
function Get-TrelloBoardCards {
    param(
        [parameter(Mandatory)]
        [string]$BoardId,
        [switch]$Members=$false
    )
    $apiCall = "/boards/${BoardId}/cards"
    if($Members) {
        $apiCall += "?members=true"
    }
    $cards = Invoke-TrelloApi -apiCall $apiCall
    $cards
}

function Get-TrelloCardChecklists {
    param(
        [parameter(Mandatory)]
        [string]$CardId
    )
    Invoke-TrelloApi -apiCall "/card/${CardId}/checklists" -params "checkItems=all"
}
function Get-TrelloListCards {
    param(
        [string]$ListId,
        [switch]$Members = $false
    )
    $params = "members=false"
    if($Members) {
        $params = "members=true"
    }
    $cards = Invoke-TrelloApi -apiCall "/lists/${ListId}/cards" -params $params
    $cards
}
function Get-TrelloCardCount {
    <#
        .Description
        Returns the count of cards by list for a specific board.
    #>
    param(
        [parameter(ParameterSetName='Name',Mandatory)]
        [string]$BoardName,
        [parameter(ParameterSetName='Id',Mandatory)]
        [string]$BoardId
    )
    $stats = [ordered]@{} # 'ordered' forces lists to appear in same order as on the board.
    $lists = $null
    if($BoardName) {
        $boards = Get-TrelloBoards
        $projectBoard = $boards |Where-Object -Property name -Value $BoardName -EQ | Select-object -First 1
        $lists = Get-TrelloBoardLists -BoardId $projectBoard.id # Returned list of lists is ordered by pos.
    } else {
        $lists = Get-TrelloBoardLists -BoardId $BoardId
    }
    foreach($list in $lists){
        $cards = Get-TrelloListCards -ListId $list.id
        $stats.Add($list.name,($cards | Measure-Object).Count)
    }
    
    [pscustomobject]$stats
}