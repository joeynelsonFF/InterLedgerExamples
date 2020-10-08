FROM ubuntu:20.04

# 0 Install Curl
RUN apt update && \
    apt -y upgrade && \
    apt -y install curl && \
    apt -y install redis-server   

###########################
# 1. Prepare Interledger
###########################

RUN mkdir -p ~/.interledger/bin && \
    export PATH=~/.interledger/bin:$PATH && \
    pushd ~/.interledger/bin &>/dev/null

# Install ilp-node and ilp-cli
RUN if [ ! -e "ilp-node" ]; then curl -L https://github.com/interledger-rs/interledger-rs/releases/download/ilp-node-latest/ilp-node-x86_64-unknown-linux-musl.tar.gz | tar xzv ; fi && \
    if [ ! -e "ilp-cli" ]; then curl -L https://github.com/interledger-rs/interledger-rs/releases/download/ilp-cli-latest/ilp-cli-x86_64-unknown-linux-musl.tar.gz | tar xzv ; fi

RUN popd &>/dev/null

# OR

# Compile fomr Source Code

# Get Rust
  # RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
  # ENV PATH="/root/.cargo/bin:${PATH}"

  # RUN alias ilp-node="cargo run --quiet --bin ilp-node --" && \
  #     alias ilp-cli="cargo run --quiet --bin ilp-cli --" && \
  #     cargo build --bin ilp-node --bin ilp-cli
    
###########################
# 2 Launch Redis
###########################

RUN mkdir -p logs











###########################
# 5. Sending a Payment
###########################

# Sending payment of 500 from Alice (on Node A) to Bob (on Node B)
# CMD ["./ilp-cli", "pay", "alice", \
#     "--auth", "alice-password", \
#     "--amount", "500", \
#     "--to", "http://localhost:8770/accounts/bob/spsp"] 
# RUN ./ilp-cli pay alice \
#     --auth alice-password \
#     --amount 500 \
#     --to http://localhost:8770/accounts/bob/spsp

# ./ilp-cli pay alice --auth alice-password --amount 500 --to http://localhost:8770/accounts/bob/spsp

###########################
# 6. Check Balances
###########################


###########################
# 7. Kill All the Services
###########################
ADD start.sh /
RUN chmod u+x /start.sh

EXPOSE 80 443 7770 8770

CMD ["./start.sh", "&&", "while", "true;", "do", "sleep", "99000;", "done"]