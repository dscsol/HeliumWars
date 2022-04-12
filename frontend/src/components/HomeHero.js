import styles from "./HomeHero.module.scss";
import linkDc from "../media/link_dc.svg";
import linkTwitter from "../media/link_twitter.svg";
import linkIg from "../media/link_ig.svg";
import linkTele from "../media/link_tele.svg";
import linkWechat from "../media/link_wechat.svg";
import { useRef, useState } from "react";

function HomeHero() {
  const subEmailRef = useRef();
  const [isSubmit, setIsSubmit] = useState(false);
  const subscribeHandler = async (e) => {
    e.preventDefault();
    const enteredSubEmail = subEmailRef.current.value;
    console.log(enteredSubEmail);
    console.log(JSON.stringify(enteredSubEmail));

    const res = await fetch("http://localhost:8000/subscribe", {
      method: "POST",
      body: JSON.stringify(enteredSubEmail),
      headers: {
        "Content-Type": "application/json",
      },
    });
    const data = await res.json();
    setIsSubmit(true);
    console.log(data);
  };
  return (
    <div className={`${styles.container}`}>
      <section className={styles.hero}>
        <div className={styles["hero-alt"]}></div>
      </section>
      <footer className={styles.footer}>
        <div className={styles["subscribe-container"]}>
          <form onSubmit={subscribeHandler}>
            <input
              type="email"
              placeholder="Your Email Address..."
              ref={subEmailRef}
            />
            <button disabled={isSubmit}>
              {isSubmit ? "Subscribed!" : "Subscribe"}
            </button>
          </form>
        </div>
        <h2>COMING SOON...</h2>
        <div className={styles.social}>
          <a href="">
            <img src={linkDc} alt="discord" />
          </a>
          <a href="https://twitter.com/helium_warz?s=21">
            <img src={linkTwitter} alt="twitter" />
          </a>
          <a href="https://www.instagram.com/helium_wars/">
            <img src={linkIg} alt="Instagram" />
          </a>
          <a href="">
            <img src={linkTele} alt="Telegram" />
          </a>
          <a href="">
            <img src={linkWechat} alt="Wechat" />
          </a>
        </div>
      </footer>
    </div>
  );
}

export default HomeHero;
