//
// Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//

package sonarqube;

import ballerina/net.http;

@Description {value:"Struct to set the SonarQube cnfiguration."}
public struct SonarQubeConfiguration {
    string uri;
    string token;
    http:ClientEndpointConfiguration clientConfig;
}

@Description {value:"Set the client configuration."}
public function <SonarQubeConfiguration sonarqubeConfig> SonarQubeConfiguration () {
    sonarqubeConfig.clientConfig = {};
}

@Description {value:"Sonarqube Endpoint struct."}
public struct SonarQubeEndpoint {
    SonarQubeConfiguration sonarqubeConfig;
    SonarQubeConnector sonarqubeConnector;
}

@Description {value:"Initialize SonarQube endpoint."}
public function <SonarQubeEndpoint ep> init (SonarQubeConfiguration sonarqubeConfig) {
    string sonarqubeURI = sonarqubeConfig.uri;
    string lastCharacter = sonarqubeURI.subString(lengthof sonarqubeURI - 1, lengthof sonarqubeURI);
    sonarqubeConfig.uri = (lastCharacter == "/") ? sonarqubeURI.subString(0, lengthof sonarqubeURI - 1) : sonarqubeURI;
    ep.sonarqubeConnector = {token:sonarqubeConfig.token,
                                httpClient:http:createHttpClient(sonarqubeConfig.uri, sonarqubeConfig.clientConfig)};
    httpClientGlobal = http:createHttpClient(sonarqubeConfig.uri, sonarqubeConfig.clientConfig);
}

public function <SonarQubeConnector ep> register (typedesc serviceType) {

}

public function <SonarQubeConnector ep> start () {

}

@Description {value:"Returns the connector that client code uses"}
@Return {value:"The connector that client code uses"}
public function <SonarQubeEndpoint ep> getClient () returns SonarQubeConnector {
    return ep.sonarqubeConnector;
}

@Description {value:"Stops the registered service"}
@Return {value:"Error occured during registration"}
public function <SonarQubeEndpoint ep> stop () {

}
