define 'compiled/calendar/CommonEvent.CalendarEvent', [
  'i18n'
  'compiled/util/semanticDateRange'
  'compiled/calendar/CommonEvent'
], (I18n, semanticDateRange, CommonEvent) ->

  I18n = I18n.scoped 'calendar'

  deleteConfirmation = I18n.t('prompts.delete_event', "Are you sure you want to delete this event?")

  class CalendarEvent extends CommonEvent
    constructor: (data, contextInfo) ->
      super data, contextInfo
      @eventType = 'calendar_event'
      @deleteConfirmation = deleteConfirmation
      @deleteURL = contextInfo.calendar_event_url

      @copyDataFromObject(data)

    copyDataFromObject: (data) =>
      data = data.calendar_event if data.calendar_event
      @object = @calendarEvent = data
      @id = "calendar_event_#{data.id}"
      @title = data.title || "Untitled"
      @start = if data.start_at then $.parseFromISO(data.start_at).time else null
      @end = if data.end_at then $.parseFromISO(data.end_at).time else null
      @allDay = data.all_day
      @editable = true
      @addClass "group_#{@contextCode()}"
      if @isAppointmentGroupEvent()
        @addClass "scheduler-event"
        if @object.reserved
          @addClass "scheduler-reserved"
        if @object.available_slots == 0
          @addClass "scheduler-full"
        if @object.available_slots == undefined || @object.available_slots > 0
          @addClass "scheduler-available"
        @editable = false

      @description = data.description

    startDate: () ->
      if @calendarEvent.start_at then $.parseFromISO(@calendarEvent.start_at).time else null

    endDate: () ->
      if @calendarEvent.end_at then $.parseFromISO(@calendarEvent.end_at).time else null

    fullDetailsURL: () ->
      # We don't support full details links to placeholder events
      if @isAppointmentGroupEvent()
        return null

      $.replaceTags(@contextInfo.calendar_event_url, 'id', @calendarEvent.id)

    displayTimeString: () ->
      semanticDateRange(@calendarEvent.start_at, @calendarEvent.end_at)

    saveDates: (success, error) =>
      @save {
        'calendar_event[start_at]': if @start then $.dateToISO8601UTC($.unfudgeDateForProfileTimezone(@start)) else ''
        'calendar_event[end_at]': if @end then $.dateToISO8601UTC($.unfudgeDateForProfileTimezone(@end)) else ''
      }, success, error

    methodAndURLForSave: () ->
      if @isNewEvent()
        method = 'POST'
        url = @contextInfo.create_calendar_event_url
      else
        method = 'PUT'
        url = if @isAppointmentGroupEvent()
                $.replaceTags @calendarEvent.url, 'id', @calendarEvent.id
              else
                $.replaceTags @contextInfo.calendar_event_url, 'id', @object.id
      [ method, url ]