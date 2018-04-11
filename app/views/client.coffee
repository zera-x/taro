window.subway ||= {}

MESSAGE_TYPES = {
  success: true,
  info: true,
  warning: true,
  danger: true
}

subway.message = (type, msg, opts={}) ->
  throw new Error('invalid alert type') unless MESSAGE_TYPES[type]
  subway.appendTo('.messages',
    ['div', {class: "alert alert-dismissible alert-#{type}", role: 'alert'},
      ['button', {class: 'close', type: 'button', 'data-dismiss': 'alert', 'aria-lable': 'Close'}
        ['span', {'aria-hidden': 'true'}, "&times;"]], msg]);
  setTimeout((() -> $('.messags').fadeOut()), opts.ttl) if opts.ttl

subway.success = (msg, opts={}) ->
  subway.message('success', msg, opts)

subway.info = (msg, opts={}) ->
  subway.message('info', msg, opts)

subway.warning = (msg, opts={}) ->
  subway.message('warning', msg, opts)

subway.danger = (msg, opts={}) ->
  subway.message('danger', msg, opts)

subway.validateRequired = (elem, msg) ->
  msg ||= "a value is required"
  val = $(elem).val()
  if !val or val.length == 0
    subway.danger(msg)
    false
  else
    true

subway.entityURL = (repo, eid) ->
  root = if subway.ROOT_URL == '/' then '' else subway.ROOT_URL
  "#{root}/admin/repos/#{repo}/entity/#{eid}"

class subway.Repo
  constructor: (@name) ->

  assert: (eid, attr, value) ->
    url = subway.entityURL(@name, eid)
    console.log('url: ', url)
    $.ajax method: "POST", url: url, data: {attr: attr, val: value}

  retract: (eid, attr, value) ->
    console.log("retract: [#{eid}, #{attr}, #{value}]")
    url = subway.entityURL(@name, eid)
    $.ajax method: "DELETE", url: url, data: {attr: attr, val: value}, error: (error) -> console.log(arguments)

subway.repo = (name) ->
  new subway.Repo name

subway.updateAttrRow = (attr, val) ->
  [['tr', {'data-attr': attr},
    ['td', {class: 'attr'},
     attr,
     ['input', {class: 'form-control', type: 'hidden', value: attr}]]
    ['td', {class: 'val'},
     ['input', {class: 'form-control', type: 'text', value: val}]]
    ['td',
     ['div', {class: 'btn-group'},
      ['button', {class: "btn btn-default", 'data-attr': attr}, "Update"],
      ['button', {class: "btn btn-default", 'data-attr': attr}, "Remove"]]]]]

subway.newCount = 0;

subway.addAttrRow = (attr, val) ->
  subway.newCount++;
  id = "new-#{subway.newCount}"
  [['tr', {'data-attr': id},
    ['td', {class: 'attr'},
     ['input', {class: 'form-control', type: 'text', value: attr, placeholder: 'job.description'}]]
    ['td', {class: 'val'},
     ['input', {class: 'form-control', type: 'text', value: val, placeholder: 'This is test job'}]]
    ['td',
     ['div', {class: 'btn-group'},
      ['button',
        {class: "btn btn-default", 'data-attr': subway.encodePunct(id), onclick: 'subway.UPDATE_ENTITY_ATTR(this)'},
         "Update"]
      ['button',
         {class: "btn btn-default", 'data-attr': subway.encodePunct(id), onclick: 'subway.REMOVE_ENTITY_ATTR(this)'},
         "Remove"]]]]]

subway.val = (elem) ->
  attr = $(elem).attr('data-attr')
  $("tr[data-attr=#{subway.encodePunct(attr)}]").find('.val input').val()

subway.attr = (elem) ->
  attr = $(elem).attr('data-attr')
  $("tr[data-attr=#{subway.encodePunct(attr)}]").find('.attr input').val()

subway.eid = () -> $('[name=eid]').val()
subway.repoName = () -> $('[name=repo]').val()

subway.ADD_ENTITY_ATTR = () ->
  subway.entityView(subway.repoName(), subway.eid()).ADD()

subway.UPDATE_ENTITY_ATTR = (elem) ->
  attr = subway.attr(elem)
  val  = subway.val(elem)
  if val and attr
    subway.entityView(subway.repoName(), subway.eid()).UPDATE(attr, val)
  else
    console.error('need values in attr and val')

subway.REMOVE_ENTITY_ATTR = (elem) ->
  attr_ = $(elem).attr('data-attr')
  if attr_.startsWith('new-')
    $("tr[data-attr=#{subway.encodePunct(attr_)}").fadeOut()
  else
    if attr = subway.attr(elem)
      console.log('attr: ', attr)
      subway.entityView(subway.repoName(), subway.eid()).REMOVE(attr)
    else
      console.error('need attr')

class subway.EntityView
  constructor: (@repo_name, @eid) ->
    @repo = new subway.Repo(@repo_name)

  ADD: (attr, val) ->
    subway.appendTo('table.entity', subway.addAttrRow(attr, val))
  
  UPDATE: (attr, val) ->
    @repo.assert(@eid, attr, val)
      .then () ->
        $("tr[data-attr=#{subway.encodePunct(attr)}]").fadeOut(() ->
          subway.appendTo('table.entity', subway.addAttrRow(attr, val)))
    
  REMOVE: (attr) ->
    @repo.retract(@eid, attr, null)
      .then (data) ->
        console.log('res: ', data)
        $("tr[data-attr=#{subway.encodePunct(attr)}").fadeOut()

subway.entityView = (repo, eid) ->
  new subway.EntityView(repo, eid)
