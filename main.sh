#!/bin/bash

# Constants
TARGET=$1
SCOPE=$2  # "org" or "enterprise"
API_VERSION="2022-11-28"
API_ACCEPT_HEADER="application/vnd.github+json"

# GraphQL query functions
get_enterprise_orgs_query() {
    cat <<-EOF
        query(\$endCursor: String) {
            enterprise(slug: "$TARGET") {
                organizations(first: 100, after: \$endCursor) {
                    nodes { login }
                    pageInfo {
                        hasNextPage
                        endCursor
                    }
                }
            }
        }
EOF
}

get_org_repos_query() {
    local org_login=$1
    cat <<-EOF
        query(\$endCursor: String) {
            organization(login: "$org_login") {
                repositories(first: 100, after: \$endCursor) {
                    nodes {
                        nameWithOwner
                        isArchived
                        isDisabled
                    }
                    pageInfo {
                        hasNextPage
                        endCursor
                    }
                }
            }
        }
EOF
}

fetch_organizations() {
    if [ "$SCOPE" = "enterprise" ]; then
        gh api graphql --paginate -f query="$(get_enterprise_orgs_query)" | \
            jq -r '.data.enterprise.organizations.nodes[] | .login' > orgs.tmp
    else
        echo "$TARGET" > orgs.tmp
    fi
}

fetch_repositories() {
    local org=$1
    echo "Fetching repos for $org..."
    gh api graphql --paginate -f query="$(get_org_repos_query "$org")" | \
        jq -r '.data.organization.repositories.nodes[] | 
        select(.isArchived == false and .isDisabled == false) | 
        .nameWithOwner' >> repos.tmp
}

enable_vulnerability_alerts() {
    local owner=$1
    local name=$2
    
    echo "Enabling Vulnerability Alerts for $owner/$name"
    gh api \
        --method PUT \
        -H "Accept: $API_ACCEPT_HEADER" \
        -H "X-GitHub-Api-Version: $API_VERSION" \
        "/repos/$owner/$name/vulnerability-alerts" || \
        echo "Error enabling alerts for $owner/$name"
}

validate_inputs() {
    if [ -z "$TARGET" ]; then
        echo "Error: Target name is required"
        echo "Usage: $0 <target_name> <scope>"
        echo "Scope: org or enterprise (default: org)"
        exit 1
    fi

    if [ -z "$SCOPE" ]; then
        SCOPE="org"
    elif [ "$SCOPE" != "org" ] && [ "$SCOPE" != "enterprise" ]; then
        echo "Error: Invalid scope. Must be 'org' or 'enterprise'"
        exit 1
    fi
}

cleanup() {
    rm -f orgs.tmp repos.tmp
}

main() {
    validate_inputs
    
    # Initialize empty repos file
    > repos.tmp
    
    # Fetch and process organizations
    fetch_organizations

    # Process each organization
    while IFS= read -r org; do
        fetch_repositories "$org"
    done < orgs.tmp

    # Remove duplicates and sort repositories
    sort -u repos.tmp -o repos.tmp

    # Enable vulnerability alerts for each repository
    while IFS= read -r repo; do
        owner=$(echo "$repo" | cut -d'/' -f1)
        name=$(echo "$repo" | cut -d'/' -f2)
        enable_vulnerability_alerts "$owner" "$name"
    done < repos.tmp

    cleanup
}

main
