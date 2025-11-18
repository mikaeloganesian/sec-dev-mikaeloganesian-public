#!/bin/bash

BASE_URL="http://localhost:8000"

echo "=========================================="
echo "Service Health Check"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    echo -n "Проверка: $description ... "
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" "$BASE_URL$endpoint")
    elif [ "$method" = "POST" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$BASE_URL$endpoint")
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL$endpoint")
    fi
    
    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✓${NC} (HTTP $http_code)"
        if [ -n "$body" ] && [ "$body" != "null" ]; then
            echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
        fi
    else
        echo -e "${RED}✗${NC} (HTTP $http_code)"
        echo "$body"
    fi
    echo ""
}

check_endpoint "GET" "/health" "" "Health check"
check_endpoint "GET" "/" "" "Root endpoint"
check_endpoint "GET" "/movies/" "" "Movies list"
check_endpoint "GET" "/courses/" "" "Courses list"

MOVIE_DATA='{"title": "Test Movie", "year": 2024, "genre": "Action"}'
check_endpoint "POST" "/movies/" "$MOVIE_DATA" "Create movie"

COURSE_DATA='{"title": "Test Course", "platform": "Udemy", "duration_hours": 10}'
check_endpoint "POST" "/courses/" "$COURSE_DATA" "Create course"

check_endpoint "GET" "/movies/1" "" "Get movie by ID"
check_endpoint "GET" "/courses/1" "" "Get course by ID"

echo "=========================================="
echo "Interactive documentation:"
echo -e "${YELLOW}http://localhost:8000/docs${NC}"
echo ""
echo "ReDoc documentation:"
echo -e "${YELLOW}http://localhost:8000/redoc${NC}"
echo "=========================================="

