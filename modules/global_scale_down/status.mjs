import { SSMClient, GetParameterCommand } from "@aws-sdk/client-ssm";
export const handler = async (event) => {
  const parameterName = process.env.hibernation_state;
  console.log("Currently checking the hibernation state");
  const getParameterCommand = new GetParameterCommand({
    Name: parameterName,
  });

  try {
    const ssmClient = new SSMClient();
    const response = await ssmClient.send(getParameterCommand);
    const parameterValue = response.Parameter.Value;
    if (parameterValue === "scaled_down"  || parameterValue === "initial" || parameterValue === "scaled_up"  || parameterValue === "scaling_up" || parameterValue === "scaling_down" || parameterValue === "error_stage" || parameterValue === "lambda_timeout") {
      return {
        statusCode: 200,
        body: JSON.stringify({
          CurrentStatus: parameterValue,
        }),
      };
    }
    return false;
  } catch (error) {
    return {
      statusCode: 400,
      body: JSON.stringify({
        Error: error,
      }),
    };
  }
};
