@app.controller 'ActivityIndexController', ['$scope', ($scope) ->
  $scope.activities = []
  $scope.totalCount = 0
  $scope.page = 1
  $scope.pageSize = 20

  table = $('.activities')

  saveState = ->
    if window.sessionStorage
      window.sessionStorage.activitiesQuery = $scope.queryString

  loadState = ->
    if window.sessionStorage
      $scope.queryString = window.sessionStorage.activitiesQuery || ''

  query = () ->
    queryData = { q: $scope.queryString, from: ($scope.page - 1) * $scope.pageSize }
    $.getJSON '/activities', queryData, (data) ->
      if data.result == 'error'
        $scope.activities = []
        $scope.totalCount = 0
        $scope.queryError = true
        console.error(data.body)
      else
        $scope.queryError = false
        $scope.totalCount = data.total
        data.activities = data.activities.sort (a,b) ->
          if a.start < b.start then 1 else -1
        $scope.activities = data.activities

      finishQuery()

  $scope.open = (id, evt) ->
    if id
      location.href = "/activities/#{id}"
    if evt
      evt.stopPropagation()

  finishQuery = ->
    $scope.$apply()
    updatePager()
    saveState()

  $scope.runQuery = () ->
    $scope.page = 1
    query()

  $scope.queryKeyPress = (evt) ->
    if evt.keyCode == 13
      $scope.runQuery()

  $scope.nextPage = () ->
    if $scope.page * $scope.pageSize <= $scope.totalCount
      $scope.page += 1
      query()

  $scope.prevPage = () ->
    if $scope.page > 1
      $scope.page -= 1
      query()

  $scope.shouldPage = () ->
    $scope.totalCount > $scope.pageSize

  $scope.fromActivity = () ->
    ($scope.page - 1) * $scope.pageSize + 1

  $scope.toActivity = () ->
    Math.min($scope.page * $scope.pageSize, $scope.totalCount)

  updatePager = ->
    pagination = $('.pager-footer')
    scrollBottom = $(document).height() - $(window).height() - $(window).scrollTop()
    if scrollBottom <= 0
      pagination.removeClass('floating')
    else
      pagination.addClass('floating')

  $(window).scroll updatePager

  loadState()
  query()
]

