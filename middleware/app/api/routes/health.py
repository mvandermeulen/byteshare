import os
from typing import Optional

import api.services.health as health_service
import utils.logger as logger
from fastapi import APIRouter, Header
from utils.auth import preprocess_external_call

router = APIRouter()

# Logger instance
log = logger.get_logger()


@router.get("/")
def health_check(
    x_api_key: Optional[str] = Header(None),
):
    """
    Perform checks to verify system health.
    For instance, check database connection, external services, etc.

    Parameters:
    - None

    Returns:
    - Status of application and external services
    """
    FUNCTION_NAME = "health_check()"
    log.info("Entering {}".format(FUNCTION_NAME))

    if x_api_key != os.getenv("AWS_API_KEY"):
        preprocess_external_call(x_api_key)

    response = health_service.health_check()

    log.info("Exiting {}".format(FUNCTION_NAME))
    return response
