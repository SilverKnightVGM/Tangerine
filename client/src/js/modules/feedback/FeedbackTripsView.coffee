class FeedbackTripsView extends Backbone.View

  className: "FeedbackTripsView"

  events: ->

    "change #county" : "onCountySelectionChange"
    "change #zone"   : "onZoneSelectionChange"
    "change #school" : "onSchoolSelectionChange"

    "click .show-feedback"    : "showFeedback"
    "click .show-lesson-plan" : "showLessonPlan"

    "click .hide-feedback"    : "hideFeedback"
    "click .hide-lesson-plan" : "hideLessonPlan"

    "click .show-survey-data" : "showSurveyData"
    "click .hide-survey-data" : "hideSurveyData"

    "click .sortable" : "sortTable"
    "click .back" : "goBack"

  valueToHuman :
    "english_word" : "English"
    "word"         : "Kiswahili"
    "operation"    : "Mathematics"
    "3"            : "Mother Tongue"

  # 
  showSurveyData: (event) ->
    $target = $(event.target)

    $target.toggle()
    $target.siblings().toggle()

    tripId = $target.attr("data-trip-id")
    $output = @$el.find(".#{tripId}-result").append("<div><img class='loading' src='images/loading.gif'></div>").find("div")

    view = new WorkflowResultView
      workflow : @workflow
      trip : @trips.get(tripId)
    view.setElement($output)

    @subViews.push view
    @["WorkflowResultView-#{tripId}"] = view

  hideSurveyData: (event) ->
    $target = $(event.target)

    $target.toggle()
    $target.siblings().toggle()

    tripId = $target.attr("data-trip-id")

    @subViews = _(@subViews).without @["WorkflowResultView-#{tripId}"]
    @["WorkflowResultView-#{tripId}"].close()

  goBack: ->
    Tangerine.router.navigate "", true

  initialize: (options) ->
    @[key] = value for key, value of options
    @$el.html('Loading...')

    @subViews = []

    @locLevels = options.levels || Tangerine.locationList.attributes.locationsLevels || []
    console.log "Init: @levels: ", @levels

    #@locLevels = ["county", "zone", "school"]
    #console.log  "in init", @

    # TODO: Here is a good example of a poor seperation of Views and
    # Controllers. The route callback `fetch` has controller logic of getting a
    # workflow and the feedback, then shows this view and it immediately starts
    # getting some data. 
    @trips = new TripResultCollection
    @trips.fetch 
      resultView : "tutorTrips"
      queryKey   : "workflow-#{@workflow.id}"
      success: => 
        # get county names
        Loc.query @locLevels, null, (res) =>
          @levelNames = res.reduce ( (obj, cur) -> obj[cur.id]=cur.label; return obj ), {}

          @isReady = true
          @render()

  hideLessonPlan: (event) ->

    $target = $(event.target)

    $target.toggle()
    $target.siblings().toggle()

    tripId = $target.attr("data-trip-id")
    @$el.find(".#{tripId}-lesson").empty()


  showLessonPlan: (event) ->

    $target = $(event.target)

    $target.toggle()
    $target.siblings().toggle()

    tripId = $target.attr("data-trip-id")
    trip   = new Trip({"_id": tripId})

    @$lessonContainer = @$el.find(".#{tripId}-lesson")

    @$lessonContainer.html "<img class='loading' src='images/loading.gif'>"

    lessonImage = new Image 
    $(lessonImage).on "load", 
      (event) =>
        if lessonImage.height is 0
          @$lessonContainer .find("img").remove?()
          @$lessonContainer.html "Sorry, no lesson plan available."
          @$lessonContainer.append(lessonImage)
        else
          @$lessonContainer.find("img").remove?()
          @$lessonContainer.append(lessonImage)


    trip.on 'sync', =>
      lessonImage.src = trip.get 'mediaOverlayFileSrc'
    trip.fetch()

  hideFeedback: (event) ->

    $target = $(event.target)

    $target.toggle()
    $target.siblings().toggle()

    tripId = $target.attr("data-trip-id")
    @$el.find(".#{tripId}").empty()


  showFeedback: (event) ->
    $target = $(event.target)
    $target.toggle()
    $target.siblings().toggle()
    tripId = $target.attr("data-trip-id")
    tripModel = {}
    @tripsByWorkflowIdCollection.models.forEach (model) =>
      if model.id == tripId
        tripModel = model
    view = new FeedbackRunView
      tripModel: tripModel 
      trip     : @trips.get(tripId)
      feedback : @feedback

    view.render()

    @subViews.push view

    @$el.find(".#{tripId}").empty().append view.$el

  onClose: ->
    for view in @subViews
      view.close()
    @$lessonContainer?.remove?()

  sortTable: ( event ) ->
    newSortAttribute = $(event.target).attr("data-attr")
    if @sortAttribute isnt newSortAttribute or @sortAttribute is null
      @sortAttribute = newSortAttribute
      @sortDirection = 1
    else
      if @sortDirection is -1
        @sortDirection = 1
        @sortAttribute = null
      else if @sortDirection is 1
        @sortDirection = -1

    @updateFeedbackList()


  render: =>

    console.log "in render", @ 

    if @isReady and @trips.length == 0
      @$el.html " 
        <h1>Feedback</h1>
        <button class='nav-button back'>Back</button>
        <p>No visits yet.</p>
      "
      return @trigger "rendered"
      
    return unless @isReady

    @$el.html "
      <h1>Feedback</h1>
      <h2>Visits</h2>
      <div class='loc-container'></div>
      <br>
      <div id='feedback-list'></div>
      "

    locViewParams = 
      filterByObj: true
      filterByObjData: @trips

    @locView = new LocView
    @locView.initialize locViewParams
    @locView.setElement @$el.find(".loc-container")
    @locView.render()
    @locView.on "change", () => @onSelectionChange()
    
    @trigger "rendered"

  # Handle the selection event from locView
  onSelectionChange: () ->
    if @locView.isComplete()
      @selectedLocation = @locView.value()
      @selectedTrips = @trips.where @selectedLocation
      console.log "selected trips", @selectedTrips

      @updateFeedbackList()
    else
      @clearFeedbackList()

  getSortArrow: (attributeName) ->
    return "&#x25bc;" if @sortAttribute is attributeName and @sortDirection is 1
    return "&#x25b2;" if @sortAttribute is attributeName and @sortDirection is -1
    return ""

  # onSchoolSelectionChange: ( event ) ->

  #   @selectedSchool = @$el.find("#school").val()
  #   @selectedZone   = @$el.find("#zone").val()
  #   @selectedCounty = @$el.find("#county").val()

  #   @selectedTrips = @trips.where
  #     county : @selectedCounty
  #     zone   : @selectedZone
  #     school : @selectedSchool

  #   @updateFeedbackList()

  clearFeedbackList: ->
    @$el.find("#feedback-list").html ""

  updateFeedbackList: ->

    if @sortAttribute in [ "subject", "stream" ]

      # to sort strings
      sortFunction = (a, b) => 
        a = a.getString(@sortAttribute)
        b = b.getString(@sortAttribute)
        if (a < b)
          result = -1
        else if (a > b)
          result = 1
        else
          result = 0
        return result * @sortDirection

    else

      # sorting numbers

      sortFunction = (a, b) => ( b.get(@sortAttribute) - a.get(@sortAttribute) ) * @sortDirection

    @selectedTrips = @selectedTrips.sort sortFunction

    #<h2>#{@schoolNames[@selectedTrips[0]?.get?("school")]? || ''}</h2>
    feedbackHtml = "
      <!-- <h2>School name here</h2> -->
      <table id='feedback-table'>
        <thead>
          <tr>
            <th nowrap class='sortable' data-attr='start_time'>Observation Start Time #{@getSortArrow("start_time")}</span></th>
            <th nowrap class='sortable' data-attr=''>&nbsp;</th>
          </tr>
        </thead>
        <tbody>
    "

    for trip,index in @selectedTrips

      tripId = trip.get('tripId')

      lessonPlanButtonsHtml = "
        <button class='command show-lesson-plan' data-trip-id='#{tripId}'>Show lesson plan</button>
        <button class='command hide-lesson-plan' data-trip-id='#{tripId}' style='display:none;'>Hide lesson plan</button>
      " unless @feedback.get("showLessonPlan")

      subject = @valueToHuman[trip.get "subject"] || ''

      resultButtonHtml = "
        <button class='command show-survey-data' data-trip-id='#{tripId}'>Show survey data</button>
        <button class='command hide-survey-data' data-trip-id='#{tripId}' style='display:none;'>Hide survey data</button>
      "


      feedbackHtml += "
        <tr>
          <td>#{moment(trip.get("start_time")).format("MMM-DD HH:mm")}</td>
          <td>
            <button class='command show-feedback' data-trip-id='#{tripId}'>Show feedback</button>
            <button class='command hide-feedback' data-trip-id='#{tripId}' style='display:none;'>Hide feedback</button>
          </td>
          <td>
            #{lessonPlanButtonsHtml || ''}
          </td>
          <td>
            #{resultButtonHtml || ''}
          </td>

        </tr>
        <tr>
          <td colspan='5' class='#{tripId}-result'></td>
        </tr>
        <tr>
          <td colspan='5' class='#{tripId}'></td>
        </tr>
        <tr>
          <td colspan='5' class='#{tripId}-lesson'></td>
        </tr>
      "
    feedbackHtml += "</tbody></table>"

    @$el.find("#feedback-list").html feedbackHtml


class WorkflowResultView extends Backbone.View
  
  events: 
    "change select" : "updateDisplay"

  updateDisplay: ->
    @$el.find(".result-display").hide()
    selectedId = @$el.find("select").val()
    @$el.find(".subtest-#{selectedId}").show()

  initialize: (options) ->

    self = @
    @[key] = value for key, value of options

    assessmentSteps = _(@workflow.getChildren()).where({"type":"assessment"})
    assessmentModelBlanks = assessmentSteps.map( (el) -> { "_id" : el.typesId })
    loadOne = (assessments) ->
      
      if assessmentModelBlanks.length == 0
        self.render()
      else
        blank = assessmentModelBlanks.pop()
        assessment = new Assessment blank
        assessments.push assessment
        assessment.deepFetch
          error: -> alert "Loading assessment failed. Please try again."
          success: ->
            assessment.questions = new Questions
            assessment.questions.fetch
              key : assessment.id
              success: ->
                loadOne(assessments)

    @assessments = []
    loadOne(@assessments)

  render: ->
    optionsHtml = []
    displayHtml = ""
    first = true

    for assessment in @assessments 
      for subtest in assessment.subtests.models
        if subtest.get("prototype") is "survey"

          hidden = if not first then "style='display:none;'" else ""
          first = false if first 
          displayHtml += "<section #{hidden} class='subtest-#{subtest.id} result-display'>"
          optionsHtml += "<option value='#{subtest.id}'>#{subtest.get('name')}</option>"

          for question in assessment.questions.models

            continue if question.get("subtestId") isnt subtest.id

            tableHtml = ""

            type = question.get('type')

            if type is "single"
              for option in question.get("options")
                unless @trip.get(question.get('name'))
                  answer = "<span color='grey'>no data</span>"
                else
                  answer = if @trip.get(question.get('name')) is option.value then "<span style='color:green'>checked</span>" else "<span style='color:red'>unchecked</span>"
                tableHtml += "
                  <tr>
                    <th>#{option.label}</th>
                    <td>#{answer}</td>
                  </tr>
                "
            else if type is "multiple"
              for option in question.get("options")
                value = @trip.get("#{question.get('name')}_#{option.value}")
                unless value
                  answer = "<span color='grey'>no data</span>"
                else
                  answer = if @trip.get("#{question.get('name')}_#{option.value}") is 1 then "<span style='color:green'>checked</span>" else "<span style='color:red'>unchecked</span>"
                tableHtml += "
                  <tr>
                    <th>#{option.label}</th>
                    <td>#{answer}</td>
                  </tr>
                "
            else
              tableHtml += "
                <tr>
                  <td colspan='2'>#{@trip.get(question.get('name'))}</td>
                </tr>
              "
            displayHtml += "
              <h3>#{question.get('prompt')}</h3>
              <table>#{tableHtml}</table>
            "
          displayHtml += "</section>"
    selectorHtml = "<select>#{optionsHtml}</select>"
    
    
    html = "
      <h2>Section</h2>
      #{selectorHtml}
      #{displayHtml}
    "

    @$el.html html
