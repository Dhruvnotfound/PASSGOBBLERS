const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");

const client = new SecretsManagerClient();

exports.handler = async (event) => {
  try {
    console.log("Event: ", JSON.stringify(event));

    const headers = {
      "Access-Control-Allow-Origin": "*", // Replace with your specific domain in production
      "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
      "Access-Control-Allow-Methods": "GET,OPTIONS"
    };
  
    // Handle OPTIONS request for CORS preflight
    if (event.httpMethod === 'OPTIONS') {
      return {
        statusCode: 200,
        headers: headers,
        body: JSON.stringify({ message: 'CORS preflight request successful' })
      };
    }
    
    const secretName = process.env.SECRET_NAME;
    console.log("Secret Name: ", secretName);

    if (!secretName) {
      throw new Error('SECRET_NAME environment variable is not set');
    }

    const command = new GetSecretValueCommand({
      SecretId: secretName,
    });

    const response = await client.send(command);
    console.log("Secrets Manager Response: ", response);

    let secret;
    if ('SecretString' in response) {
      secret = response.SecretString;
    } else {
      const buff = Buffer.from(response.SecretBinary, 'base64');
      secret = buff.toString('ascii');
    }

    const secretJSON = JSON.parse(secret);
    console.log("Parsed Secret JSON: ", secretJSON);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Secret retrieved successfully',
        secretKeys: Object.keys(secretJSON)
      })
    };
  } catch (error) {
    console.error('Error retrieving secret:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error retrieving secret',
        error: error.message
      })
    };
  }
};