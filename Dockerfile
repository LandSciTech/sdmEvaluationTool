# Usage:
#
# docker build --platform linux/amd64 -t sdmevaltool:v1 .
#
# docker run -p 8080:8080 sdmevaltool:v1

FROM rocker/r2u:22.04

RUN installGithub.r LandSciTech/sdmEvaluationTool/sdmEvalToolCore
RUN installGithub.r LandSciTech/sdmEvaluationTool/sdmEvalToolUI

RUN groupadd app && useradd -g app app
WORKDIR /home/app

ADD https://peter.solymos.org/testapi/sdmevaltool/sdm_evaluation_results.zip .
RUN unzip ./sdm_evaluation_results.zip

RUN chown app:app -R /home/app
USER app
EXPOSE 8080
CMD ["R", "-q", "-e", "library(sdmEvalToolCore);library(sdmEvalToolUI);sdm_tool(options = list(host = '0.0.0.0', port = 8080))"]
