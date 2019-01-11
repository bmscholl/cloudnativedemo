import logging
import json

import azure.functions as func

def main(req: func.HttpRequest, doc: func.Out[func.Document]) -> func.HttpResponse:

    vote_data = req.get_json()
    voter_id = vote_data.get('voter_id')
    vote = vote_data.get('vote')

    logging.info(f'Processing vote for {vote} by {voter_id}')

    doc.set(func.Document.from_json(json.dumps(vote_data)))

    return func.HttpResponse('OK', status_code=200)
