# Invoice Factoring Platform

A decentralized peer-to-peer invoice factoring platform built on Stacks blockchain using Clarity smart contracts.

## Overview

This platform enables businesses to tokenize their outstanding invoices and sell them to investors at a discount, providing immediate liquidity while offering investors opportunities to earn returns through trade finance.

## Features

- **Invoice Tokenization**: Convert invoices into tradeable digital assets
- **Peer-to-Peer Trading**: Direct marketplace between invoice issuers and investors  
- **Automated Settlement**: Smart contract-based payment processing
- **Risk Management**: Built-in validation and security measures
- **Platform Fee Structure**: Transparent fee model with configurable rates

## How It Works

1. **Create Invoice**: Businesses create invoices specifying debtor, amount, discount rate, and due date
2. **Purchase Invoice**: Investors browse and purchase invoices at discounted rates
3. **Payment Processing**: Debtors pay invoices directly to the platform
4. **Settlement**: Automatic distribution of payments to invoice buyers

## Smart Contract Functions

### Public Functions

- `create-invoice`: Create a new tradeable invoice
- `purchase-invoice`: Buy an invoice at discounted rate
- `pay-invoice`: Process payment from debtor to buyer
- `deposit`: Add funds to platform balance
- `withdraw`: Remove funds from platform balance

### Read-Only Functions

- `get-invoice`: Retrieve invoice details
- `get-user-balance`: Check user's platform balance
- `calculate-purchase-price`: Calculate discounted invoice price

## Getting Started

### Prerequisites

- Clarinet CLI installed
- Stacks wallet for testing

### Installation

```bash
git clone <repository-url>
cd invoice-factoring-platform
clarinet check
```

### Testing

```bash
clarinet test
```

## Contract Architecture

The contract uses the following data structures:

- **Invoices Map**: Stores invoice details and status
- **User Balances Map**: Tracks platform balances for all users
- **Platform Variables**: Configurable parameters like fee rates

## Security Features

- Owner-only administrative functions
- Input validation for all parameters
- Status-based access control
- Overflow protection for calculations

## License

MIT License

## Contributing

1. Fork the repository
2. Create feature branch
3. Submit pull request with detailed description

## Support

For questions or issues, please open a GitHub issue.