import azure.functions as func
import json

# Dictionary of Avenger code names and real names
avengers = {
    'IronMan': 'Tony Stank',
    'CaptainAmerica': 'Steve Rogers',
    'BlackWidow': 'Natasha Romanoff',
    'Hulk': 'Bruce Banner',
    'Thor': 'Thor Odinson',
    'Hawkeye': 'Clint Barton',
}

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

@app.route(route="avengers/{codename?}", methods=["GET"])
def GetAvenger(req: func.HttpRequest) -> func.HttpResponse:
    # The code name is part of the URL path and is optional
    code_name = req.route_params.get('codename', None)

    if code_name:
        real_name = avengers.get(code_name)
        if not real_name:
            return func.HttpResponse(
                 f"The Avenger code name '{code_name}' is not recognized.",
                 status_code=404
            )
        return func.HttpResponse(json.dumps({'realName': real_name}), mimetype="application/json")
    else:
        # If no codename is provided, return the entire list
        return func.HttpResponse(json.dumps(avengers), mimetype="application/json")

@app.route(route="avengers/{codeName}", methods=["DELETE"])
def DeleteAvenger(req: func.HttpRequest) -> func.HttpResponse:

    method = req.method
    if method == 'DELETE':
        # Handle DELETE request
        code_name = req.route_params.get('codeName', None)
        return func.HttpResponse(f"Avenger: {code_name} has been deleted.", status_code=200)
    else:
        return func.HttpResponse("This HTTP method is not supported.", status_code=405)
