"""Get vendor related data from Pyxis"""

import argparse
import logging
from urllib.parse import urljoin

from operatorcert import pyxis
from operatorcert.logger import setup_logger
from operatorcert.utils import store_results

LOGGER = logging.getLogger("operator-cert")


def setup_argparser() -> argparse.ArgumentParser:  # pragma: no cover
    """
    Setup argument parser

    Returns:
        Any: Initialized argument parser
    """
    parser = argparse.ArgumentParser(
        description="Get the Certification Project related data"
    )
    parser.add_argument(
        "--org-id", help="Unique identifier of the organization in Red Hat Connect"
    )
    parser.add_argument(
        "--pyxis-url",
        default="https://pyxis.engineering.redhat.com/",
        help="Base URL for Pyxis container metadata API",
    )
    parser.add_argument("--verbose", action="store_true", help="Verbose output")

    return parser


def get_vendor_related_data(pyxis_url: str, org_id: str) -> None:
    """
    Get vendor related data from Pyxis based on the organization ID

    Args:
        pyxis_url (str): Pyxis base URL
        org_id (str): Organization ID
    """
    rsp = pyxis.get(
        urljoin(
            pyxis_url,
            f"/v1/vendors/org-id/{org_id}",
        )
    )

    rsp.raise_for_status()

    vendor = rsp.json()

    store_results({"vendor": vendor})


def main() -> None:  # pragma: no cover
    """
    Main function
    """
    parser = setup_argparser()
    args = parser.parse_args()

    log_level = "INFO"
    if args.verbose:
        log_level = "DEBUG"
    setup_logger(level=log_level)

    get_vendor_related_data(args.pyxis_url, args.org_id)


if __name__ == "__main__":  # pragma: no cover
    main()
