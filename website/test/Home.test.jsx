import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import Home from '../src/pages/Home/Home';

describe('Home Page', () => {
  it('renders without crashing', () => {
    render(
      <MemoryRouter>
        <Home show={true} />
      </MemoryRouter>
    );
    expect(screen.getByText((content, element) => {
      const hasText = (node) => node.textContent === "Your Intelligent Assistant for Local Files";
      return element.tagName.toLowerCase() === 'h1' && hasText(element);
    })).toBeInTheDocument();
  });

  it('renders Download Now button', () => {
    render(
      <MemoryRouter>
        <Home show={true} />
      </MemoryRouter>
    );
    expect(screen.getByText(/Download Now/i)).toBeInTheDocument();
  });

  it('renders View GitHub button', () => {
    render(
      <MemoryRouter>
        <Home show={true} />
      </MemoryRouter>
    );
    expect(screen.getByText(/View GitHub/i)).toBeInTheDocument();
  });
});
