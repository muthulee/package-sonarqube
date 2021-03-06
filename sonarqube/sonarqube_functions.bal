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

import ballerina/mime;
import ballerina/net.http;

@Description {value:"Check whether the response from sonarqube server has an error field."}
@Param {value:"response: http Response."}
function checkResponse (http:Response response) {
    json responseJson = getContentByKey(response, ERRORS);
    if (!isAnEmptyJson(responseJson)) {
        error err = {message:""};
        foreach item in responseJson {
            err.message = err.message + ((item.msg != null) ? item.msg.toString() : "") + ".";
        }
        throw err;
    }
}

@Description {value:"Get content from a json specified by key."}
@Param {value:"response: http Response."}
@Param {value:"key: String key."}
@Return {value:"jsonPayload: Content (of type json) specified by the key."}
function getContentByKey (http:Response response, string key) returns (json) {
    var getContent = response.getJsonPayload();
    json jsonPayload = {};
    mime:EntityError jsonErr = {};
    match getContent {
        mime:EntityError endpointErr => jsonErr = endpointErr;
        json content => jsonPayload = content;
    }
    if (isAnEmptyJson(jsonPayload)) {
        error err = {};
        if (response.reasonPhrase != "") {
            err = {message:response.reasonPhrase};
            throw err;
        }
        err = {message:"Server response payload is null."};
        throw err;
    } else if (jsonErr.message != "") {
        error err = {message:"Error in retrieving json payload."};
        throw err;
    }
    return jsonPayload[key];
}

@Description {value:"Check whether a json is empty."}
@Return {value:"True if json is empty false otherwise."}
function isAnEmptyJson (json jsonValue) returns (boolean) {
    try {
        string stringVal = jsonValue.toString();
        if (stringVal == "{}") {
            return true;
        }
        return false;
    } catch (error e) {
        return true;
    }
    return false;
}

@Description {value:"Return the project from a json array of projects."}
@Param {value:"projectName:Name of the project."}
@Param {value:"projectList:Project List."}
@Return {value:"project:Details of the project specified by name."}
function getProjectFromList (string projectName, json projectList) returns (Project) {
    foreach projectData in projectList {
        Project project = <Project, getProjectDetails()>projectData;
        if (projectName == project.name) {
            return project;
        }
    }
    return {};
}

@Description {value:"Returns value of the metric in measures field of a json."}
@Param {value:"response: http Response."}
@Return {value:"value: Value of the metric field in json."}
@Return {value:"err: if error occured in getting value of the measures field in the json."}
function getMetricValue (string projectKey, SonarQubeConnector sonarqubeConnector, string metricName) returns (string) {
    http:Response response = {};
    http:Request request = {};
    http:HttpConnectorError connectionError = {};
    sonarqubeConnector.constructAuthenticationHeaders(request);
    string requestPath = API_MEASURES + "?" + COMPONENT_KEY + "=" + projectKey + "&" + METRIC_KEY + "=" + metricName;
    match sonarqubeConnector.httpClient.get(requestPath, request) {
        http:Response res => response = res;
        http:HttpConnectorError connectErr => connectionError = connectErr;
    }
    error err = {};
    if (connectionError.message != "") {
        err = {message:connectionError.message};
        throw err;
    }
    checkResponse(response);
    json component = getContentByKey(response, COMPONENT);
    json metricValue = component[MEASURES][0][VALUE];
    if (isAnEmptyJson(metricValue)) {
        err = {message:"Cannot find " + metricName.replace("_", " ") + " for this project."};
        throw err;
    }
    return metricValue.toString();
}

@Description {value:"Convert a given json to Issue."}
@Param {value:"issueDetails:Json to convert."}
@Return {value:"issue:convereted ."}
function convertToIssue (json issueDetails) returns Issue {
    Issue issue = {};
    issue.key = !isAnEmptyJson(issueDetails[KEY]) ? issueDetails[KEY].toString() : "";
    issue.severity = !isAnEmptyJson(issueDetails[SEVERITY]) ? issueDetails[SEVERITY].toString() : "";
    issue.status = !isAnEmptyJson(issueDetails[STATUS]) ? issueDetails[STATUS].toString() : "";
    issue.issueType = !isAnEmptyJson(issueDetails[TYPE]) ? issueDetails[TYPE].toString() : "";
    issue.description = !isAnEmptyJson(issueDetails[MESSAGE]) ? issueDetails[MESSAGE].toString() : "";
    issue.author = !isAnEmptyJson(issueDetails[AUTHOR]) ? issueDetails[AUTHOR].toString() : "";
    issue.creationDate = !isAnEmptyJson(issueDetails[CREATION_DATE]) ? issueDetails[CREATION_DATE].toString() : "";
    issue.assignee = !isAnEmptyJson(issueDetails[ASSIGNEE]) ? issueDetails[ASSIGNEE].toString() : "";
    json positionInfo = issueDetails[ISSUE_RANGE];
    issue.position = {};
    issue.position.startLine = (!isAnEmptyJson(positionInfo)) ? (!isAnEmptyJson(positionInfo[START_LINE]) ?
                                                                  positionInfo[START_LINE].toString() : "") : "";
    issue.position.endLine = (!isAnEmptyJson(positionInfo)) ? (!isAnEmptyJson(positionInfo[END_LINE]) ? positionInfo[END_LINE]
                                                                                                        .toString() : "") : "";
    json tags = issueDetails[TAGS];
    int count = 0;
    if (!isAnEmptyJson(tags)) {
        string[] tagList = [];
        foreach tag in tags {
            tagList[count] = tag.toString();
            count = count + 1;
        }
        issue.tags = tagList;
        count = 0;
    }
    json transitions = issueDetails[TRANSITIONS];
    if (!isAnEmptyJson(transitions)) {
        string[] workflowTransitions = [];
        foreach transition in transitions {
            workflowTransitions[count] = transition.toString();
            count = count + 1;
        }
        issue.workflowTransitions = workflowTransitions;
        count = 0;
    }
    json comments = issueDetails[COMMENTS];
    if (!isAnEmptyJson(comments)) {
        Comment[] commentList = [];
        foreach comment in comments {
            commentList[count] = <Comment, getComment()>comment;
            count = count + 1;
        }
        issue.comments = commentList;
    }
    return issue;
}

