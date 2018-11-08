window.taro ||= {}

MESSAGE_TYPES = {
  success: true,
  info: true,
  warning: true,
  danger: true
}

taro.message = (type, msg, opts={}) ->
  throw new Error('invalid alert type') unless MESSAGE_TYPES[type]
  taro.appendTo('.messages',
    ['div', {class: "alert alert-dismissible alert-#{type}", role: 'alert'},
      ['button', {class: 'close', type: 'button', 'data-dismiss': 'alert', 'aria-lable': 'Close'}
        ['span', {'aria-hidden': 'true'}, "&times;"]], msg]);
  setTimeout((() -> $('.messags').fadeOut()), opts.ttl) if opts.ttl

taro.success = (msg, opts={}) ->
  taro.message('success', msg, opts)

taro.info = (msg, opts={}) ->
  taro.message('info', msg, opts)

taro.warning = (msg, opts={}) ->
  taro.message('warning', msg, opts)

taro.danger = (msg, opts={}) ->
  taro.message('danger', msg, opts)

taro.validateRequired = (elem, msg) ->
  msg ||= "a value is required"
  val = $(elem).val()
  if !val or val.length == 0
    taro.danger(msg)
    false
  else
    true

taro.entityURL = (repo, eid) ->
  root = if taro.ROOT_URL == '/' then '' else taro.ROOT_URL
  "#{root}/admin/repos/#{repo}/entity/#{eid}"

class taro.Repo
  constructor: (@name) ->

  assert: (eid, attr, value) ->
    url = taro.entityURL(@name, eid)
    console.log('url: ', url)
    $.ajax method: "POST", url: url, data: {attr: attr, val: value}

  retract: (eid, attr, value) ->
    console.log("retract: [#{eid}, #{attr}, #{value}]")
    url = taro.entityURL(@name, eid)
    $.ajax method: "DELETE", url: url, data: {attr: attr, val: value}, error: (error) -> console.log(arguments)

taro.repo = (name) ->
  new taro.Repo name

taro.updateAttrRow = (attr, val) ->
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

taro.newCount = 0;

taro.addAttrRow = (attr, val) ->
  taro.newCount++;
  id = "new-#{taro.newCount}"
  [['tr', {'data-attr': id},
    ['td', {class: 'attr'},
     ['input', {class: 'form-control', type: 'text', value: attr, placeholder: 'job.description'}]]
    ['td', {class: 'val'},
     ['input', {class: 'form-control', type: 'text', value: val, placeholder: 'This is test job'}]]
    ['td',
     ['div', {class: 'btn-group'},
      ['button',
        {class: "btn btn-default", 'data-attr': taro.encodePunct(id), onclick: 'taro.UPDATE_ENTITY_ATTR(this)'},
         "Update"]
      ['button',
         {class: "btn btn-default", 'data-attr': taro.encodePunct(id), onclick: 'taro.REMOVE_ENTITY_ATTR(this)'},
         "Remove"]]]]]

taro.val = (elem) ->
  attr = $(elem).attr('data-attr')
  $("tr[data-attr=#{taro.encodePunct(attr)}]").find('.val input').val()

taro.attr = (elem) ->
  attr = $(elem).attr('data-attr')
  $("tr[data-attr=#{taro.encodePunct(attr)}]").find('.attr input').val()

taro.eid = () -> $('[name=eid]').val()
taro.repoName = () -> $('[name=repo]').val()

taro.ADD_ENTITY_ATTR = () ->
  taro.entityView(taro.repoName(), taro.eid()).ADD()

taro.UPDATE_ENTITY_ATTR = (elem) ->
  attr = taro.attr(elem)
  val  = taro.val(elem)
  if val and attr
    taro.entityView(taro.repoName(), taro.eid()).UPDATE(attr, val)
  else
    console.error('need values in attr and val')

taro.REMOVE_ENTITY_ATTR = (elem) ->
  attr_ = $(elem).attr('data-attr')
  if attr_.startsWith('new-')
    $("tr[data-attr=#{taro.encodePunct(attr_)}").fadeOut()
  else
    if attr = taro.attr(elem)
      console.log('attr: ', attr)
      taro.entityView(taro.repoName(), taro.eid()).REMOVE(attr)
    else
      console.error('need attr')

class taro.EntityView
  constructor: (@repo_name, @eid) ->
    @repo = new taro.Repo(@repo_name)

  ADD: (attr, val) ->
    taro.appendTo('table.entity', taro.addAttrRow(attr, val))
  
  UPDATE: (attr, val) ->
    @repo.assert(@eid, attr, val)
      .then () ->
        $("tr[data-attr=#{taro.encodePunct(attr)}]").fadeOut(() ->
          taro.appendTo('table.entity', taro.addAttrRow(attr, val)))
    
  REMOVE: (attr) ->
    @repo.retract(@eid, attr, null)
      .then (data) ->
        console.log('res: ', data)
        $("tr[data-attr=#{taro.encodePunct(attr)}").fadeOut()

taro.entityView = (repo, eid) ->
  new taro.EntityView(repo, eid)
