import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import Home from '../src/pages/Home/Home';

describe('Home Page', () => {
  it('renders without crashing', () => {
    render(<Home show={true} />);
    expect(screen.getByText(/Your Second Brain/i)).toBeInTheDocument();
  });

  it('renders Get Started button', () => {
    render(<Home show={true} />);
    expect(screen.getByText(/Get Started Free/i)).toBeInTheDocument();
  });

  it('renders View GitHub button', () => {
    render(<Home show={true} />);
    expect(screen.getByText(/View GitHub/i)).toBeInTheDocument();
  });
});
