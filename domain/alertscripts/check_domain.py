#!/usr/bin/env python

"""
dependency library:
pip install aliyun-python-sdk-core
pip install aliyun-python-sdk-domain
pip install aliyun-python-sdk-httpdns
"""

import json
import sys

from aliyunsdkcore.client import AcsClient
from aliyunsdkdomain.request.v20180129.QueryDomainListRequest import QueryDomainListRequest
from aliyunsdkcore.acs_exception.exceptions import ClientException
from aliyunsdkcore.acs_exception.exceptions import ServerException
from aliyunsdkcore.request import RpcRequest
from aliyunsdkhttpdns.request.v20160201.ListDomainsRequest import ListDomainsRequest

AccessKeyId = "xxxxxxxxxx"
AccessKeySecret="xxxxxxxxxxxxxx"

def get_expire_domain(domain, AccessKeyId = AccessKeyId, AccessKeySecret=AccessKeySecret):
    clt =AcsClient(AccessKeyId, AccessKeySecret)

    request = QueryDomainListRequest()
    request.set_PageSize(10)
    request.set_PageNum(1)
    request.set_DomainName(domain)
    result = clt.do_action_with_exception(request)

    res_dict = json.loads(result)
    return res_dict.get("Data").get("Domain")[0].get("ExpirationCurrDateDiff")


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('Usage:' + sys.argv[0] + ' DOMAIN_NAME')
    else:
        domain = sys.argv[1]
        expire_days = get_expire_domain(domain)
        
        print(expire_days)



