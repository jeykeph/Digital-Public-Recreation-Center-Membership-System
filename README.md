# Digital Public Recreation Center Membership System

A comprehensive blockchain-based membership management system for public recreation centers built on the Stacks blockchain using Clarity smart contracts.

## System Overview

This system manages all aspects of a public recreation center through five interconnected smart contracts:

### Core Contracts

1. **Membership Registration** (`membership-registration.clar`)
    - Member enrollment and registration
    - Membership type management (Basic, Premium, Family)
    - Membership renewals and status tracking
    - Access level permissions

2. **Class Scheduling** (`class-scheduling.clar`)
    - Fitness class creation and management
    - Instructor assignments
    - Member class bookings and cancellations
    - Class capacity and waitlist management

3. **Equipment Maintenance** (`equipment-maintenance.clar`)
    - Exercise equipment inventory tracking
    - Maintenance scheduling and logging
    - Equipment status monitoring
    - Repair request management

4. **Locker Rental** (`locker-rental.clar`)
    - Daily and monthly locker assignments
    - Locker availability tracking
    - Rental payment processing
    - Locker access management

5. **Special Event Booking** (`event-booking.clar`)
    - Private facility rentals
    - Birthday party bookings
    - Special event scheduling
    - Event payment and deposit handling

## Features

### Membership Management
- Multiple membership tiers with different access levels
- Automated membership expiration tracking
- Family membership support with dependent management
- Guest pass system

### Class & Activity Management
- Flexible class scheduling system
- Instructor certification tracking
- Automatic waitlist management
- Class rating and feedback system

### Facility Management
- Comprehensive equipment tracking
- Preventive maintenance scheduling
- Real-time equipment status updates
- Maintenance cost tracking

### Revenue Management
- Automated payment processing
- Multiple payment methods support
- Revenue tracking and reporting
- Refund and credit management

## Technical Architecture

### Data Structures
- **Members**: Principal-based identity with membership details
- **Classes**: Time-based scheduling with capacity limits
- **Equipment**: Asset tracking with maintenance history
- **Lockers**: Location-based rental system
- **Events**: Booking system with deposit requirements

### Security Features
- Principal-based access control
- Role-based permissions (Admin, Staff, Member)
- Input validation and error handling
- State consistency checks

### Error Handling
- Comprehensive error codes for all operations
- Descriptive error messages
- Transaction rollback on failures
- Input validation at contract level

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js 18+ for testing
- Stacks wallet for deployment

### Installation

1. Clone the repository
2. Install dependencies:
   \`\`\`bash
   npm install
   \`\`\`

3. Run tests:
   \`\`\`bash
   npm test
   \`\`\`

4. Deploy contracts:
   \`\`\`bash
   clarinet deploy
   \`\`\`

### Usage Examples

#### Register a New Member
\`\`\`clarity
(contract-call? .membership-registration register-member
"John Doe"
"john@email.com"
u1) ;; Basic membership
\`\`\`

#### Book a Fitness Class
\`\`\`clarity
(contract-call? .class-scheduling book-class u1 u1234567890)
\`\`\`

#### Rent a Locker
\`\`\`clarity
(contract-call? .locker-rental rent-locker u15 u30) ;; Locker 15 for 30 days
\`\`\`

## Testing

The system includes comprehensive tests using Vitest:

- Unit tests for each contract function
- Integration tests for cross-contract workflows
- Edge case and error condition testing
- Performance and gas optimization tests

Run the test suite:
\`\`\`bash
npm test
\`\`\`

## Contract Addresses

After deployment, update these addresses in your frontend application:

- Membership Registration: `ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.membership-registration`
- Class Scheduling: `ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.class-scheduling`
- Equipment Maintenance: `ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.equipment-maintenance`
- Locker Rental: `ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.locker-rental`
- Event Booking: `ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.event-booking`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For technical support or questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation wiki
