(require '[clojure.java.io :as io]
         '[clojure.string :as str])
(import '[java.net InetAddress]
        '[java.nio.file Files Paths CopyOption StandardCopyOption]
        '[java.nio.file.attribute FileAttribute]
        '[java.time OffsetDateTime]
        '[java.time.format DateTimeFormatter ResolverStyle]
        '[java.util Locale])

(def log-pattern
  #"^(\S+) \S+ \S+ \[([^\]]+)\] \"([!#$%&'*+.^_`|~0-9A-Za-z-]+) ((?:\\.|[^\"\\\s])+) HTTP/[0-9]+(?:\.[0-9]+)?\" ([1-5][0-9]{2}) ([0-9]+|-)$")

(def time-format
  (.withResolverStyle
    (DateTimeFormatter/ofPattern "dd/MMM/uuuu:HH:mm:ss xx" Locale/ENGLISH)
    ResolverStyle/STRICT))

(defn valid-time? [value]
  (try (OffsetDateTime/parse value time-format) true
       (catch java.time.format.DateTimeParseException _ false)))

(defn valid-ip? [value]
  (if (str/includes? value ":")
    (and (re-matches #"[0-9A-Fa-f:.]+" value)
         (try (InetAddress/getByName value) true (catch Exception _ false)))
    (let [parts (str/split value #"\." -1)]
      (and (= 4 (count parts))
           (every? #(and (re-matches #"[0-9]{1,3}" %)
                         (<= (Integer/parseInt %) 255)) parts)))))

(defn parse-line [line]
  (when-let [[_ ip stamp method path status bytes] (re-matches log-pattern line)]
    (when (and (valid-ip? ip) (valid-time? stamp))
      [ip stamp method (str/replace path #"\\([\"\\])" "$1") status
       (if (= bytes "-") "0" bytes)])))

(defn csv-field [value]
  (str "\"" (str/replace value "\"" "\"\"") "\""))

(defn convert-file [input output]
  (let [destination (.toAbsolutePath (Paths/get output (make-array String 0)))
        temporary (Files/createTempFile (.getParent destination) ".apache-" ".csv"
                                        (make-array FileAttribute 0))
        converted (atom 0)
        skipped (atom 0)]
    (try
      (with-open [reader (io/reader input :encoding "UTF-8")
                  writer (io/writer (.toFile temporary) :encoding "UTF-8")]
        (.write writer "ip,time,method,path,status,bytes\r\n")
        (doseq [line (line-seq reader)]
          (if-let [row (parse-line line)]
            (do (.write writer (str (str/join "," (map csv-field row)) "\r\n"))
                (swap! converted inc))
            (swap! skipped inc))))
      (Files/move temporary destination
                  (into-array CopyOption [StandardCopyOption/REPLACE_EXISTING]))
      (println (str "Converted: " @converted " Skipped: " @skipped))
      (finally (Files/deleteIfExists temporary)))))

(try
  (when-not (= 2 (count *command-line-args*))
    (throw (IllegalArgumentException. "usage: clojure main.clj <input.log> <output.csv>")))
  (apply convert-file *command-line-args*)
  (catch Exception error
    (binding [*out* *err*] (println "Error:" (.getMessage error)))
    (System/exit 1)))
