# Bootstrap tabs

$('.btn-default a').click  (e) ->
  e.preventDefault()
  $(this).tab('show')
 $.fn.observeField = (opts = {}) ->
   field = $(this)
   key_timeout = null
   last_value = null
   options =
     onFilled: () ->
     onEmpty: () ->
     onChange: () ->
   options = $.extend(options, opts)
 
   keyChange = () ->
     if field.val().length > 0
       options.onFilled()
     else
       options.onEmpty()
 
     if field.val() == last_value && field.val().length != 0
       return
     lastValue = field.val()
 
     options.onChange()
 
   field.data('observed', true)
 
   field.bind 'keydown', (e) ->
     if(key_timeout)
       clearTimeout(key_timeout)

     key_timeout = setTimeout(->
       keyChange()
     , 400)

$ ->
  $('.control-group').tooltip
    selector: 'a[data-toggle=tooltip]'

  # form ui

  $('input[type="radio"]').wrap '<span class="radio-btn"></span>'
  $('.radio-btn').on 'click', ->
    _this = $(this)
    block = _this.parent().parent()
    block.find('input:radio').attr 'checked', false
    block.find('.radio-btn').removeClass 'checkedRadio'
    _this.addClass 'checkedRadio'
    _this.find('input:radio').attr 'checked', true
    return

  $('input[type="checkbox"]').wrap '<span class="check-box"></span>'
  $.fn.toggleCheckbox = ->
    @attr 'checked', not @attr('checked')
    return

  $('.check-box').on 'click', ->
    $(this).find(':checkbox').toggleCheckbox()
    $(this).toggleClass 'checkedBox'
    return

  $('input[type="radio"]:checked').parent().addClass 'checkedRadio'
  $('input[type="checkbox"]:checked').parent().addClass 'checkedBox'
  $('select').wrap '<span class="select-wrap"></span>'
  $(".select-wrap").click ->
    $(this).toggleClass "select-btn"
  return



