FROM rocker/r-ver:4.6.0
WORKDIR /dry-age-monitor

# pak config variables to force system requirement install as needed
# see <https://pak.r-lib.org/reference/pak-config.html>
ENV PKG_SYSREQS=TRUE
ENV R_PKG_SYSREQS2=TRUE

RUN install2.r -e pak


COPY DESCRIPTION .
RUN R -e "pak::local_install_deps('./DESCRIPTION')"
