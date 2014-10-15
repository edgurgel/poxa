var websocket;
var counter = 0;
$(document).ready(init);

function init() {
  $("#disconnect").hide();

  if(!("WebSocket" in window)) {
    $('#status').append('<p><span style="color: red;">websockets are not supported </span></p>');
  };

  $('#connect').submit(function(event) {
    var appKey = $('#appKey').val();
    var secret = $('#secret').val();
    connect(appKey, secret);
    event.preventDefault();
  });

  $('#disconnect').submit(function(event) {
    disconnect();
    var appKey = $('#appKey').val("");
    var secret = $('#secret').val("");
    event.preventDefault();
  });
};

function connect(appKey, secret) {
  var qs = authQS(appKey, secret);
  var host = window.location.host;
  websocket = new WebSocket(websocketProtocol() + "//" + host  + "/console?" + qs);
  websocket.onopen = function(evt) { onOpen(evt) };
  websocket.onclose = function(evt) { onClose(evt) };
  websocket.onmessage = function(evt) { onMessage(evt) };
  websocket.onerror = function(evt) { onError(evt) };
};

function authQS(appKey, secret) {
  var auth_key = appKey;
  var auth_timestamp = Math.round(new Date().getTime() / 1000);
  var params = { auth_key:auth_key,
                 auth_timestamp:auth_timestamp,
                 auth_version:"1.0" } ;
  var auth_signature = CryptoJS.HmacSHA256("GET\n/console\n" + $.param(params), secret).toString();
  return $.param($.extend({ }, params, { auth_signature:auth_signature }));
}

function disconnect() {
  websocket.close();
};

function isSecure() {
  return window.location.protocol == 'https:';
}

function websocketProtocol() {
  return isSecure() ? 'wss:' : 'ws:';
}

function onOpen(evt) {
  $("#connect").hide();
  $("#disconnect").show();
  console.log("Websocket connected");
};

function onClose(evt) {
  console.log("Websocket closed");
  $("#connect").show();
  $("#disconnect").hide();
};

function onMessage(evt) {
  incrementCounter();
  var data = JSON.parse(evt.data);
  addEvent(data.type, data.socket, data.details, data.time);
};

function onError(evt) {
  console.log("Error: " + evt);
};

function incrementCounter() {
  counter++;
  $('#counter').text(counter);
};

function addEvent(type, socket, details, time) {
  var label = '<td class="' + labelClass(type) + '">' + type + '</td>';
  var row = label +
            '<td>' + socket + '</td>' +
            '<td>' + details + '</td>' +
            '<td>' + time + '</td>';
  $('#events > tbody:last').prepend('<tr>' + row + '</tr>');
};

function labelClass(type) {
  switch (type) {
    case 'Connection':
      return 'success';
    case 'Disconnection':
      return 'danger';
    case 'Subscribed':
      return 'info';
    case 'Unsubscribed':
      return 'info';
    case 'Occupied':
      return 'info';
    case 'Vacated':
      return 'info';
    default:
      return 'warning';
  }
};

