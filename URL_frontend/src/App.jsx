import { useEffect, useState } from "react";
import {
  Link,
  ArrowRight,
  Check,
  X,
  RefreshCw,
  Copy,
  Trash2,
  Search,
  Globe,
  FileText,
  Code2,
  Rocket,
  Sun,
} from "lucide-react";

import "./App.css";

const API_URL = "https://3li9pyqc7g.execute-api.ap-south-1.amazonaws.com";

function App() {
  const [url, setUrl] = useState("");
  const [urls, setUrls] = useState([]);
  const [search, setSearch] = useState("");

  const [loading, setLoading] = useState(false);
  const [loadingUrls, setLoadingUrls] = useState(false);

  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  // --------------------------------------------------
  // GET ALL URLS
  // --------------------------------------------------

  const fetchUrls = async () => {
    try {
      setLoadingUrls(true);
      setError("");

      const response = await fetch(`${API_URL}/all`);

      if (!response.ok) {
        throw new Error("Unable to fetch shortened URLs");
      }

      const data = await response.json();

      // Assuming /all returns:
      // [
      //   {
      //      "short_code": "aB72x",
      //      "original_url": "https://google.com"
      //   }
      // ]

      setUrls(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoadingUrls(false);
    }
  };

  // --------------------------------------------------
  // LOAD URLS WHEN PAGE OPENS
  // --------------------------------------------------

  useEffect(() => {
    fetchUrls();
  }, []);

  // --------------------------------------------------
  // SHORTEN URL
  // --------------------------------------------------

  const shortenUrl = async (event) => {
  event.preventDefault();

  if (!url.trim()) {
    setError("Please enter a URL");
    return;
  }

  try {
    setLoading(true);
    setError("");
    setSuccess("");

    const response = await fetch(`${API_URL}/shorten`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        original_url: url.trim(),
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(
        data?.error || "Unable to shorten URL"
      );
    }

    console.log("Shorten API response:", data);

    setUrl("");
    setSuccess("URL shortened successfully!");

    await fetchUrls();

    setTimeout(() => {
      setSuccess("");
    }, 4000);

  } catch (err) {
    console.error("Shorten URL error:", err);
    setError(err.message);
  } finally {
    setLoading(false);
  }
};

  // --------------------------------------------------
  // DELETE URL
  // --------------------------------------------------

  const deleteUrl = async (shortCode) => {
    const confirmed = window.confirm(
      "Are you sure you want to delete this shortened URL?"
    );

    if (!confirmed) {
      return;
    }

    try {
      setError("");

      const response = await fetch(
        `${API_URL}/delete/${shortCode}`,
        {
          method: "DELETE",
        }
      );

      if (!response.ok) {
        const errorData = await response.json().catch(() => null);

        throw new Error(
          errorData?.detail || "Unable to delete URL"
        );
      }

      // Remove deleted URL from UI immediately
      setUrls((currentUrls) =>
        currentUrls.filter(
          (item) => item.short_code !== shortCode
        )
      );
    } catch (err) {
      setError(err.message);
    }
  };

  // --------------------------------------------------
  // COPY SHORT URL
  // --------------------------------------------------

  const copyShortUrl = async (shortCode) => {
    const shortUrl = `${API_URL}/${shortCode}`;

    try {
      await navigator.clipboard.writeText(shortUrl);

      setSuccess("Short URL copied to clipboard!");

      setTimeout(() => {
        setSuccess("");
      }, 3000);
    } catch (err) {
      setError("Unable to copy URL");
    }
  };

  // --------------------------------------------------
  // SEARCH
  // --------------------------------------------------

  const filteredUrls = urls.filter((item) => {
    const searchText = search.toLowerCase();

    return (
      item.original_url
        ?.toLowerCase()
        .includes(searchText) ||
      item.short_code
        ?.toLowerCase()
        .includes(searchText)
    );
  });

  // --------------------------------------------------
  // ICON FOR URL
  // --------------------------------------------------

  const getIcon = (index) => {
    const icons = [Globe, FileText, Code2];

    const Icon = icons[index % icons.length];

    return <Icon size={25} strokeWidth={2} />;
  };

  return (
    <div className="app">

      {/* ============================================ */}
      {/* HEADER */}
      {/* ============================================ */}

      <header className="header">
        <div className="header-left">
          <div className="logo">
            <Link size={25} />
          </div>

          <h1>URL Shortner</h1>
        </div>

        <div className="header-right">
          <button className="theme-button">
            <Sun size={21} />
          </button>
        </div>
      </header>

      {/* ============================================ */}
      {/* MAIN */}
      {/* ============================================ */}

      <main className="main">

        {/* ======================================== */}
        {/* HERO */}
        {/* ======================================== */}

        <section className="hero">

          <div className="hero-decoration dots">
            <span />
            <span />
            <span />
            <span />
            <span />
            <span />
            <span />
            <span />
            <span />
          </div>

          <div className="hero-decoration circle" />

          <div className="hero-content">

            <h2>Shorten Your Links</h2>

            <p>
              Transform long, complicated URLs into short,
              shareable links in seconds.
            </p>

            <form
              className="shorten-form"
              onSubmit={shortenUrl}
            >
              <div className="input-wrapper">

                <Link size={24} />

                <input
                  type="url"
                  value={url}
                  onChange={(e) => setUrl(e.target.value)}
                  placeholder="Paste your long URL here..."
                  required
                />

              </div>

              <button
                type="submit"
                disabled={loading}
                className="shorten-button"
              >
                {loading ? (
                  <>
                    <RefreshCw
                      size={20}
                      className="spin"
                    />

                    Shortening...
                  </>
                ) : (
                  <>
                    Shorten URL
                    <ArrowRight size={20} />
                  </>
                )}
              </button>
            </form>

            <div className="example">
              Example:{" "}
              <span>
                https://www.example.com/some/very/long/path
              </span>
            </div>

          </div>
        </section>

        {/* ======================================== */}
        {/* SUCCESS MESSAGE */}
        {/* ======================================== */}

        {success && (
          <div className="success-message">

            <div className="success-icon">
              <Check size={20} />
            </div>

            <div>
              <strong>{success}</strong>

              <p>
                Your short link is ready to use.
              </p>
            </div>

            <button
              onClick={() => setSuccess("")}
              className="message-close"
            >
              <X size={20} />
            </button>

          </div>
        )}

        {/* ======================================== */}
        {/* ERROR MESSAGE */}
        {/* ======================================== */}

        {error && (
          <div className="error-message">

            <div>
              <strong>Error</strong>
              <p>{error}</p>
            </div>

            <button
              onClick={() => setError("")}
              className="message-close"
            >
              <X size={20} />
            </button>

          </div>
        )}

        {/* ======================================== */}
        {/* URL LIST HEADER */}
        {/* ======================================== */}

        <section className="url-section">

          <div className="section-header">

            <h2>My Shortened URLs</h2>

            <div className="section-actions">

              <div className="search-box">
                <Search size={19} />

                <input
                  type="text"
                  placeholder="Search your links..."
                  value={search}
                  onChange={(e) =>
                    setSearch(e.target.value)
                  }
                />
              </div>

              <button
                className="refresh-button"
                onClick={fetchUrls}
                disabled={loadingUrls}
              >
                <RefreshCw
                  size={18}
                  className={loadingUrls ? "spin" : ""}
                />

                Refresh
              </button>

            </div>

          </div>

          {/* ====================================== */}
          {/* URL CARDS */}
          {/* ====================================== */}

          <div className="url-list">

            {loadingUrls ? (
              <div className="empty-state">
                <RefreshCw
                  size={30}
                  className="spin"
                />

                <p>Loading your links...</p>
              </div>
            ) : filteredUrls.length === 0 ? (
              <div className="empty-state">
                <Link size={40} />

                <h3>No shortened URLs</h3>

                <p>
                  Create your first shortened URL above.
                </p>
              </div>
            ) : (
              filteredUrls.map((item, index) => {

                const shortUrl =
                  `${API_URL}/${item.short_code}`;

                return (
                  <div
                    className="url-card"
                    key={item.short_code}
                  >

                    {/* LEFT */}
                    <div className="url-card-left">

                      <div
                        className={`url-icon icon-${index % 3}`}
                      >
                        {getIcon(index)}
                      </div>

                      <div className="url-details">

                        <h3>
                          {getDomain(item.original_url)}
                        </h3>

                        <p className="original-url">
                          {item.original_url}
                        </p>

                      </div>

                    </div>

                    {/* RIGHT */}
                    <div className="url-card-right">

                      <div className="short-url">
                        <a
                          href={shortUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                        >
                          {shortUrl}
                        </a>
                      </div>

                      <button
                        className="copy-button"
                        title="Copy short URL"
                        onClick={() =>
                          copyShortUrl(item.short_code)
                        }
                      >
                        <Copy size={19} />
                      </button>

                      <button
                        className="delete-button"
                        onClick={() =>
                          deleteUrl(item.short_code)
                        }
                      >
                        <Trash2 size={18} />
                        Delete
                      </button>

                    </div>

                  </div>
                );
              })
            )}

          </div>
        </section>

        {/* ======================================== */}
        {/* FOOTER */}
        {/* ======================================== */}

        <footer className="footer">

          <div className="rocket">
            <Rocket size={22} />
          </div>

          <p>
            Built with ❤️ using{" "}
            <span>React</span> and{" "}
            <span>FastAPI</span>
          </p>

        </footer>

      </main>
    </div>
  );
}


// ================================================
// GET DOMAIN FROM URL
// ================================================

function getDomain(url) {
  try {
    const parsedUrl = new URL(url);

    return parsedUrl.hostname.replace("www.", "");
  } catch {
    return "Shortened URL";
  }
}

export default App;