// GraphWise initial schema & sample data

// Constraints / indexes
CREATE CONSTRAINT IF NOT EXISTS FOR (u:User) REQUIRE u.userId IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (p:Portfolio) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (c:Company) REQUIRE c.symbol IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (h:Holding) REQUIRE (h.internalId) IS UNIQUE;

// Create a sample user, portfolio, company, holding, and a transaction
MERGE (u:User {userId: 'user_local', name: 'Local User'})
MERGE (p:Portfolio {id: 'portfolio_default', name: 'Default Portfolio'}) 
MERGE (u)-[:OWNS]->(p)

MERGE (c:Company {symbol: 'AAPL', name: 'Apple Inc', sector: 'Technology'})
MERGE (h:Holding {internalId: 'H-AAPL-1', symbol: 'AAPL', quantity: 10.0, avgCost: 150.0})
MERGE (p)-[:HAS_HOLDING]->(h)
MERGE (h)-[:IS_COMPANY]->(c)

CREATE (t:Transaction {txId: apoc.create.uuid(), type: 'BUY', symbol: 'AAPL', quantity: 10.0, price: 150.0, date: date()})
MERGE (h)-[:HAS_TRANSACTION]->(t)

// sample signal node
CREATE (s:Signal {id: apoc.create.uuid(), kind: 'PRICE_ALERT', message: 'Sample alert: price moved > 5%', createdAt: datetime()})
MERGE (h)-[:HAS_SIGNAL]->(s)

// Example usage query (comment)
RETURN 'init complete' as status;
