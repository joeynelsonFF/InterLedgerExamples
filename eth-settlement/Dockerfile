FROM ubuntu:20.04

# 0 Install Curl
RUN apt update && \
    apt -y upgrade && \
    apt -y install curl redis-server git

###########################
# 1. Prepare Interledger
###########################

RUN mkdir -p ~/.interledger/bin && \
    export PATH=~/.interledger/bin:$PATH && \
    pushd ~/.interledger/bin &>/dev/null



# Compile fomr Source Code

# Get Rust
  RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
  ENV PATH="/root/.cargo/bin:${PATH}"

  RUN git clone https://github.com/interledger-rs/interledger-rs
  
  #ADD ../interledger-rs /

  # RUN alias ilp-node="cargo run --quiet --bin ilp-node --" && \
  #     alias ilp-cli="cargo run --quiet --bin ilp-cli --" && \
  #     cargo build --bin ilp-node --bin ilp-cli
    
###########################
# 2 Launch Redis
###########################

RUN mkdir -p logs


ADD start.sh /
RUN chmod u+x /start.sh

EXPOSE 80 443 7770 8770

CMD ["./start.sh", "&&", "while", "true;", "do", "sleep", "99000;", "done"]