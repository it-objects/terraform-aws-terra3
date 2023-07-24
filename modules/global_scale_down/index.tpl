<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Scale Operations</title>
    <style>
    body { text-align: center; padding: 150px; }
    h1 { font-size: 50px; color: black; }
    button { padding: 20px; font-size: 30px; margin: 20px; cursor: pointer; color: green}
    #statusMessage { font-size: 24px; }
    #message-display { font-size: 24px; color: green }
    .active { color: red; }
  </style>
</head>

<body>
<h1>Global Scale Up/Down Operations</h1>

<form id="authForm" >
<label for="token-input">Enter token:</label>
<input id="token-input" type="password" placeholder="Your token" name="token-input" required>
<button id="scale_down_button"  type="submit" onclick="handle_scale_down()">Scale Down</button>
<button id="scale_up_button"  type="submit" onclick="handle_scale_up()">Scale Up</button>
<p id="statusMessage">Click the button to start the Lambda function.</p>
<pre id="message-display"></pre>
</form>

<script>
    function invoke_scale_down_lambda() {
        var scale_down_button = document.getElementById("scale_down_button");
        scale_down_button.disabled = true; // Disable the button

        event.preventDefault();

        // Add the 'disabled-button' class to blur the button
        scale_down_button.classList.add('disabled-button');

        // Show the "in progress" message
        document.getElementById('statusMessage').innerText = "Scale Down Lambda function is in progress...";

        var token = document.getElementById('token-input').value;
        //document.getElementById('message-display').textContent = 'Entered token: ' + token;

        var apiEndpoint = "${scale_down_api_endpoint}";
        var url = apiEndpoint + "?token=" + token;


        fetch(url)
        .then(response => response.json())
        .then(data => {
            document.getElementById('message-display').textContent = JSON.stringify(data);
            })
        .catch((error) => {
            console.error('Error:', error);
        });

        setTimeout(function () {
          scale_down_button.disabled = false;
          scale_down_button.classList.remove("active");
        }, 500); // Adjust the delay as needed
    }

    function change_scale_down_button_color() {
        var scale_down_button = document.getElementById("scale_down_button");
        scale_down_button.classList.add("active");
        setTimeout(function () {
          scale_down_button.classList.remove("active");
        }, 30000);
    }

    function handle_scale_down() {
        invoke_scale_down_lambda();
        change_scale_down_button_color();
    }


    function invoke_scale_up_lambda() {
        var scale_up_button = document.getElementById("scale_up_button");
        scale_up_button.disabled = true; // Disable the button

        event.preventDefault();

        // Add the 'disabled-button' class to blur the button
        scale_up_button.classList.add('disabled-button');

        // Show the "in progress" message
        document.getElementById('statusMessage').innerText = "Scale Up Lambda function is in progress...";

        var token = document.getElementById('token-input').value;
        //document.getElementById('message-display').textContent = 'Entered token: ' + token;

        var apiEndpoint = "${scale_up_api_endpoint}";
        var url = apiEndpoint + "?token=" + token;


        fetch(url)
        .then(response => response.json())
        .then(data => {
            document.getElementById('message-display').textContent = JSON.stringify(data);
            })
        .catch((error) => {
            console.error('Error:', error);
        });

        setTimeout(function () {
          scale_up_button.disabled = false;
          scale_up_button.classList.remove("active");
        }, 500); // Adjust the delay as needed
    }

    function change_scale_up_button_color() {
        var scale_up_button = document.getElementById("scale_up_button");
        scale_up_button.classList.add("active");
        setTimeout(function () {
          scale_up_button.classList.remove("active");
        }, 30000);
    }

    function handle_scale_up() {
        invoke_scale_up_lambda();
        change_scale_up_button_color();
    }

  </script>
</body>
</html>
