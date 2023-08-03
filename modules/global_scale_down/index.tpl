<!DOCTYPE html>
<html  lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Environment Hibernation</title>
    <style>
      body {
        text-align: center;
        padding: 150px;
      }
      h1 {
        font-size: 50px;
        color: black;
      }
      label[for="ScaleDownToken"] {
        font-size: 30px;
      }
      input#ScaleDownToken {
        font-size: 20px;
        padding: 8px;
      }
      button {
        padding: 20px;
        font-size: 30px;
        margin: 20px;
        cursor: pointer;
        color: green;
      }
      #StatusMessage {
        font-size: 24px;
      }
      #FunctionLog {
        font-size: 24px;
        color: green;
      }
      #StatusLog {
        font-size: 24px;
        color: green;
      }
    </style>
  </head>
  <body>
    <h1>${solution_name} : Global Scale Up/Down Operations</h1>
    <form id="StatusForm" onsubmit="return status_lambda()">
      <button id="StatusButton" type="submit">Current Status</button>
      <pre id="StatusLog"> </pre>
    </form>

    <form id="ScaleDownForm" onsubmit="invoke_scale_down_lambda()">
      <label for="ScaleDownToken">Enter token:</label>
      <input
        id="ScaleDownToken"
        type="password"
        placeholder="Your token value"
        name="token"
      />
      <p style="font-size: 14px; color: #666">
        (Hint: Your token value can be found in the AWS Systems Manager
        under Parameter Store with the name "/${solution_name}/global_scale_down/token".)
      </p>
      <button id="ScaleDownButton" type="submit">Scale Down</button>
    </form>

    <form id="ScaleUpForm" onsubmit="return invoke_scale_up_lambda()">
      <input id="ScaleUpToken" type="hidden" name="token" />
      <button id="ScaleUpButton" type="submit">Scale Up</button>
    </form>

    <form id="MessageForm">
      <p id="StatusMessage"> </p>
      <pre id="FunctionLog"> </pre>
    </form>

    <script>

        function status_lambda() {
        var StatusLogButton = document.getElementById("StatusLogButton");

        event.preventDefault();

        var token = document.getElementById("ScaleDownToken").value;

        var apiEndpoint = "${status_api_endpoint}";
        fetch(apiEndpoint)
          .then((response) => response.json())
          .then((data) => {
            document.getElementById("StatusLog").textContent =
              JSON.stringify(data);
          })
          .catch((error) => {
            console.error("Error:", error);
          });
      }

      function invoke_scale_down_lambda() {
        var ScaleDownButton = document.getElementById("ScaleDownButton");

        event.preventDefault();

        // Show the "pressed button" message
        document.getElementById("StatusMessage").innerText =
          "You have pressed Scale Down Button.";

        var token = document.getElementById("ScaleDownToken").value;

        if (token === "") {
          alert("Token cannot be empty. Please enter a valid token.");
          return false; // Prevent form submission
        }

        var apiEndpoint = "${scale_down_api_endpoint}";
        var url = apiEndpoint + "?token=" + token;
        fetch(url)
          .then((response) => response.json())
          .then((data) => {
            document.getElementById("FunctionLog").textContent =
              JSON.stringify(data);
          })
          .catch((error) => {
            console.error("Error:", error);
          });
      }

      function invoke_scale_up_lambda() {
        var ScaleUpButton = document.getElementById("ScaleUpButton");

        event.preventDefault();

        // Show the "pressed button" message
        document.getElementById("StatusMessage").innerText =
          "You have pressed Scale Up Button.";

        const ScaleDownTokenInput = document.getElementById("ScaleDownToken");
        const ScaleUpTokenInput = document.getElementById("ScaleUpToken");
        const token = ScaleDownTokenInput.value.trim();
        ScaleUpTokenInput.value = token; // Set the token in the hidden input field

        if (token === "") {
          alert("Token cannot be empty. Please enter a valid token.");
          return false; // Prevent form submission
        }

        //var token = document.getElementById("token").value;
        var apiEndpoint = "${scale_up_api_endpoint}";
        var url = apiEndpoint + "?token=" + token;
        fetch(url)
          .then((response) => response.json())
          .then((data) => {
            document.getElementById("FunctionLog").textContent =
              JSON.stringify(data);
          })
          .catch((error) => {
            console.error("Error:", error);
          });
      }
    </script>
  </body>
</html>
